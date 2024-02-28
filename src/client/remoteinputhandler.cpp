#include "remoteinputhandler.h"
#include "client/keycode.h"
#include "hud.h"

#include <cassert>
#include <stdexcept>
#include <string>
#include <string_view>
#include <sstream>

#include <capnp/message.h>
#include <capnp/serialize.h>
#include <capnp/rpc.h>
#include <kj/array.h>


namespace detail {

kj::Promise<void> MinetestImpl::init(InitContext context) {
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
    m_chan->m_obs_cv.wait(lock, [this] { return m_chan->m_has_obs; });
    context.getResults().setObservation(m_chan->m_obs_builder.asReader());
    m_chan->m_has_obs = false;
    m_chan->m_obs_cv.notify_one();
  }

  std::unique_lock<std::mutex> lock(m_chan->m_action_mutex);
  // We can't return until action has been consumed, because it will be destroyed
  // when the context is destroyed.
  m_chan->m_action_cv.wait(lock, [this] { return m_chan->m_action == nullptr; });
  return kj::READY_NOW;
}

} // namespace detail

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
};

void RemoteInputHandler::fill_observation(irr::video::IImage *image, float reward) {
  std::unique_lock<std::mutex> lock(m_chan.m_obs_mutex);
  m_chan.m_obs_cv.wait(lock, [this] { return !m_chan.m_has_obs; });

  m_chan.m_obs_builder.setReward(reward);
  m_chan.m_image_builder.setWidth(image->getDimension().Width);
  m_chan.m_image_builder.setHeight(image->getDimension().Height);
  m_chan.m_image_builder.setData(
      capnp::Data::Reader(reinterpret_cast<const uint8_t *>(image->getData()),
                          image->getImageDataSizeInBytes()));
  m_chan.m_has_obs = true;
  m_chan.m_obs_cv.notify_one();
  image->drop();
}

void RemoteInputHandler::step(float dtime) {
  // skip first loop, because we don't have an observation yet
  // as draw is called after step
  if (m_is_first_loop) {
    m_is_first_loop = false;
    return;
  }

  // We don't model key release events, keys need to be re-pressed every step.
  // Rationale: there's only one place in the engine were keyRelease events are
  // used, and it doesn't seem important.
  clearInput();

  KeyPress new_key_code;
  // receive action
  {
    std::unique_lock<std::mutex> lock(m_chan.m_action_mutex);
    m_chan.m_action_cv.wait(lock, [this] { return m_chan.m_action; });

    for (auto keyEvent : m_chan.m_action->getKeyEvents()) {
      new_key_code = keycache.key[static_cast<int>(keyEvent)];
      if (!m_key_is_down[new_key_code]) {
        m_key_was_pressed.set(new_key_code);
      }
      m_key_is_down.set(new_key_code);
      m_key_was_down.set(new_key_code);
    }
    m_mouse_speed = v2s32(m_chan.m_action->getMouseDx(), m_chan.m_action->getMouseDy());
    // mousepos is reset to (WIDTH/2, HEIGHT/2) after every iteration of main game
    // loop unit is pixels, origin is top left corner, bounds is (0,0) to (WIDTH,
    // HEIGHT)
    m_mouse_pos += m_mouse_speed;
    m_chan.m_action = nullptr;
    m_chan.m_action_cv.notify_one();
  }

  // send current observation
  irr::video::IVideoDriver *driver = m_rendering_engine->get_video_driver();
  irr::video::IImage *image = driver->createScreenShot(video::ECF_R8G8B8);

  // parse reward from hud
  // during game startup, the hud is not yet initialized, so there'll be no
  // reward for the first 1-2 steps
  float reward{};
  for (u32 i = 0; i < m_player->maxHudId(); ++i) {
    auto hud_element = m_player->getHud(i);
    if (hud_element->name == "reward") {
      // parse 'Reward: <reward>' from hud
      constexpr char kRewardHUDPrefix[] = "Reward: ";
      std::string_view reward_string = hud_element->text;
      reward_string.remove_prefix(std::size(kRewardHUDPrefix) - 1); // -1 for null terminator
      // I'd rather use std::from_chars, but it's not available in libc++ yet.
      std::stringstream ss{std::string(reward_string)};
      ss >> reward;
      break;
    }
  }

  // copying the image into the capnp message is slow, so we do it in a separate thread
  std::thread([this, image, reward]() {
    fill_observation(image, reward);
  }).detach();
};

void RemoteInputHandler::clearInput() {
  m_key_is_down.clear();
  m_key_was_pressed.clear();
  m_mouse_wheel = 0;
}
