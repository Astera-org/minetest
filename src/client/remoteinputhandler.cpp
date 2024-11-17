#include "remoteinputhandler.h"
#include "client/keycode.h"
#include "hud.h"
#include "remoteplayer.h"
#include "server.h"
#include "server/player_sao.h"
#include "client/content_cao.h"
#include <cassert>
#include <mutex>
#include <sstream>
#include <stdexcept>
#include <string>
#include <capnp/message.h>
#include <capnp/serialize.h>
#include <capnp/rpc.h>
#include <kj/array.h>
#include <vector>
#include <limits>

#pragma GCC diagnostic push
#if __clang__
#pragma GCC diagnostic error "-Weverything"
#pragma GCC diagnostic ignored "-Wc++98-compat"
#pragma GCC diagnostic ignored "-Wctad-maybe-unsupported"
#if (__clang_major__ > 18) || (__clang_major__ == 18 && __clang_minor__ >= 1)
#pragma GCC diagnostic ignored "-Wunsafe-buffer-usage"
#endif
#endif
#pragma GCC diagnostic ignored "-Wpadded"

namespace detail {

kj::Promise<void> MinetestImpl::init(InitContext) {
  std::unique_lock<std::mutex> lock(m_chan->m_action_mutex);
  m_chan->m_did_init = true;
  m_chan->m_action_cv.notify_one();
  return kj::READY_NOW;
}

kj::Promise<void> MinetestImpl::step(StepContext context) {
  Action::Reader action = context.getParams().getAction();
  {
    std::unique_lock<std::mutex> lock(m_chan->m_action_mutex);
    m_chan->m_action = &action;
    m_chan->m_action_cv.notify_one();
  }

  {
    std::unique_lock<std::mutex> lock(m_chan->m_obs_mutex);
    m_chan->m_obs_cv.wait(lock, [this] { return m_chan->m_obs_msg_builder != nullptr; });
    auto obs = m_chan->m_obs_msg_builder->getRoot<Observation>();
    context.getResults().setObservation(obs.asReader());
    m_chan->m_obs_msg_builder.reset();
    m_chan->m_obs_cv.notify_one();
  }

  std::unique_lock<std::mutex> lock(m_chan->m_action_mutex);
  // We can't return until action has been consumed, because it will be destroyed
  // when the context is destroyed.
  m_chan->m_action_cv.wait(lock, [this] { return m_chan->m_action == nullptr; });
  return kj::READY_NOW;
}

} // namespace detail

namespace {
  s32 to_s32(u32 value) {
    // TODO: when c++-20 use https://en.cppreference.com/w/cpp/utility/in_range
    if (value > std::numeric_limits<s32>::max()) {
      auto message = std::stringstream{};
      message << "u32 " << value << " does not fit in s32";
      throw std::range_error{message.str()};
    }
    return static_cast<s32>(value);
  }
}

RemoteInputHandler::RemoteInputHandler(const std::string &endpoint,
                                       RenderingEngine *rendering_engine,
                                       MyEventReceiver *receiver)
    : m_rendering_engine(rendering_engine),
      m_receiver(receiver) {

  std::unique_lock<std::mutex> lock(m_chan.m_action_mutex);
  std::thread([chan = &m_chan, endpoint]() {
    kj::AsyncIoContext capnp_io_context(kj::setupAsyncIo());
    kj::Network& network = capnp_io_context.provider->getNetwork();
    kj::Own<kj::NetworkAddress> addr = network.parseAddress(endpoint).wait(capnp_io_context.waitScope);
    kj::Own<kj::ConnectionReceiver> listener = addr->listen();
    // Ask the listener for the port rather than just logging endpoint,
    // in case it was chosen automatically.
    uint port = listener->getPort();
    if (port) {
      infostream << "RemoteInputHandler: Listening on port TCP port " << port << "...";
    } else {
      infostream << "RemoteInputHandler: Listening on " << endpoint << "...";
    }
    capnp::TwoPartyServer server(kj::heap<detail::MinetestImpl>(chan));
    server.listen(*listener).wait(capnp_io_context.waitScope);
  }).detach();
  m_chan.m_action_cv.wait(lock, [this] { return m_chan.m_did_init; });
}

void RemoteInputHandler::step(float dtime) {
  // skip first loop, because we don't have an observation yet
  // as draw is called after step
  if (m_is_first_loop) {
    m_is_first_loop = false;
    return;
  }

  KeyList new_key_is_down;
  v2f mouse_movement;

  // Receive next action.
  {
    std::unique_lock<std::mutex> lock(m_chan.m_action_mutex);
    m_chan.m_action_cv.wait(lock, [this] { return m_chan.m_action; });

    // Copy data out of action.
    for (auto keyEvent : m_chan.m_action->getKeyEvents()) {
      KeyPress key_code = keycache.key[static_cast<int>(keyEvent)];
      new_key_is_down.set(key_code);
    }
    mouse_movement = v2f(
      static_cast<float>(m_chan.m_action->getMouseDx()),
      static_cast<float>(m_chan.m_action->getMouseDy())
    );

    m_chan.m_action = nullptr;
    m_chan.m_action_cv.notify_one();
  }

  // Process action.
  {
    // Compute pressed keys.
    m_key_was_pressed.clear();
    for (const auto& key_code: new_key_is_down) {
      if (!m_key_is_down[key_code]) {
        m_key_was_pressed.set(key_code);
      }
    }

    // Compute released keys.
    m_key_was_released.clear();
    for (const auto& key_code: m_key_is_down) {
      if (!new_key_is_down[key_code]) {
        m_key_was_released.set(key_code);
      }
    }

    // Apply new key state.
    m_key_is_down.clear();
    m_key_is_down.append(new_key_is_down);
    m_key_was_down.clear();
    m_key_was_down.append(new_key_is_down);

    // Apply mouse state.
    // mousepos is reset to (WIDTH/2, HEIGHT/2) after every iteration of main game
    // loop unit is pixels, origin is top left corner, bounds is (0,0) to (WIDTH,
    // HEIGHT)
    m_mouse_speed = v2s32::from(dtime * mouse_movement);
    m_mouse_pos += m_mouse_speed;
    m_mouse_wheel = 0;
  }

  float remote_input_handler_time_step = 0.0f;
  g_settings->getFloatNoEx("remote_input_handler_time_step", remote_input_handler_time_step);
  if(remote_input_handler_time_step > 0.0f) {
    gServer->AsyncRunStep(remote_input_handler_time_step);
  }

  m_should_send_observation = true;
}

void RemoteInputHandler::step_post_render() {
  if (!m_should_send_observation) {
    return;
  }

  m_should_send_observation = false;

  auto builder_buffer = new capnp::MallocMessageBuilder();
  auto obs_builder = builder_buffer->initRoot<Observation>();

  {
    irr::video::IImage *image = m_rendering_engine->get_video_driver()->createScreenShot(video::ECF_R8G8B8);
    auto builder = obs_builder.initImage();
    builder.setWidth(to_s32(image->getDimension().Width));
    builder.setHeight(to_s32(image->getDimension().Height));
    builder.setData(capnp::Data::Reader(reinterpret_cast<const uint8_t *>(image->getData()), image->getImageDataSizeInBytes()));
    image->drop();
  }

  {
    const auto lock_guard = std::lock_guard { m_player->exposeTheMutex() };
    const auto& hud_elements = m_player->exposeTheHud();
    constexpr auto is_text = [](const HudElement * element) noexcept { return element->type == HUD_ELEM_TEXT; };
    const auto text_count = std::count_if(hud_elements.cbegin(), hud_elements.cend(), is_text);

    auto builder = obs_builder.initHudElements();
    auto entries = builder.initEntries(static_cast<unsigned int>(text_count));
    auto entry_it = entries.begin();
    for (const auto& hud_element : hud_elements) {
      if (!is_text(hud_element)) continue;
      entry_it->setKey(hud_element->name);
      entry_it->setValue(hud_element->text);
      ++entry_it;
    }
  }

  {
    auto server_lock = std::lock_guard { gServer->getEnvMutex() };

    auto remote_player = gServer->getEnv().getPlayer(m_player->getName());
    if (remote_player == nullptr) {
      throw std::runtime_error("remote_player is null");
    }

    auto remote_player_sao = remote_player->getPlayerSAO();
    if (remote_player_sao == nullptr) {
      throw std::runtime_error("remote_player sao is null");
    }

    auto remote_player_props = remote_player_sao->accessObjectProperties();
    if (remote_player_props == nullptr) {
      throw std::runtime_error("remote_player object properties is null");
    }

    // We are retrieving these from the server because `m_player-getCAO()` can return a null pointer.
    obs_builder.setPlayerHealth(remote_player_sao->getHP());
    obs_builder.setPlayerHealthMax(remote_player_props->hp_max);
    obs_builder.setPlayerBreath(remote_player_sao->getBreath());
    obs_builder.setPlayerBreathMax(remote_player_props->breath_max);
    obs_builder.setPlayerIsDead(remote_player_sao->isDead());

    const auto& player_meta = remote_player_sao->getMeta().getStrings();
    auto builder = obs_builder.initPlayerMetadata();
    auto entries = builder.initEntries(static_cast<unsigned int>(player_meta.size()));
    auto entry_it = entries.begin();
    for (const auto& [key, value] : player_meta) {
      entry_it->setKey(key);
      entry_it->setValue(value);
      ++entry_it;
    }
  }

  std::unique_lock<std::mutex> lock(m_chan.m_obs_mutex);
  m_chan.m_obs_cv.wait(lock, [this] { return m_chan.m_obs_msg_builder == nullptr; });
  m_chan.m_obs_msg_builder.reset(builder_buffer);
  m_chan.m_obs_cv.notify_one();
}

#pragma GCC diagnostic pop
