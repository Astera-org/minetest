#pragma once

#include "client/renderingengine.h"
#include "gui/mainmenumanager.h"
#include "inputhandler.h"
#include "remoteclient.capnp.h"

#include <condition_variable>
#include <map>
#include <memory>
#include <mutex>
#include <string>

#include <capnp/message.h>
#include <capnp/rpc-twoparty.h>
#include <capnp/serialize-packed.h>
#include <kj/async-io.h>

#pragma GCC diagnostic push 
#pragma GCC diagnostic error "-Weverything"
#pragma GCC diagnostic ignored "-Wc++98-compat"
#pragma GCC diagnostic ignored "-Wpadded"
#pragma GCC diagnostic ignored "-Wunsafe-buffer-usage"

namespace detail {
struct Channel {
  std::condition_variable m_action_cv;
  std::mutex m_action_mutex;
  Action::Reader *m_action{nullptr}; // GUARDED_BY(m_action_mutex)
  bool m_did_init{}; // GUARDED_BY(m_action_mutex)

  std::condition_variable m_obs_cv;
  std::mutex m_obs_mutex;
  std::unique_ptr<::capnp::MallocMessageBuilder> m_obs_msg_builder{}; // GUARDED_BY(m_obs_mutex)

  Channel() {}
};

class MinetestImpl final : public Minetest::Server {
public:
  MinetestImpl(Channel *chan) : m_chan(chan) {}
  kj::Promise<void> init(InitContext context) override;
  kj::Promise<void> step(StepContext context) override;
private:
  Channel *m_chan;
};
} // namespace detail

class RemoteInputHandler : public InputHandler {
public:
  RemoteInputHandler(const std::string &endpoint,
                     RenderingEngine *rendering_engine,
                     MyEventReceiver *receiver);

  virtual ~RemoteInputHandler() noexcept override = default;

  bool isDetached() const override { return true; }

  virtual bool isKeyDown(GameKeyType k) override {
    return m_key_is_down[keycache.key[k]];
  }
  virtual bool wasKeyDown(GameKeyType k) override {
    bool b = m_key_was_down[keycache.key[k]];
    if (b)
      m_key_was_down.unset(keycache.key[k]);
    return b;
  }
  virtual bool wasKeyPressed(GameKeyType k) override {
    return m_key_was_pressed[keycache.key[k]];
  }
  virtual bool wasKeyReleased(GameKeyType k) override {
    return m_key_was_released[keycache.key[k]];
  }
  virtual bool cancelPressed() override {
    return m_key_was_down[keycache.key[KeyType::ESC]];
  }
  virtual float getJoystickSpeed() override {
    auto axes = getJoystickAxes();
    return (axes.X == 0 && axes.Y == 0) ? 0.0 : 1.0;
  }
  virtual float getJoystickDirection() override {
    auto axes = getJoystickAxes();
    return (axes.X == 0 && axes.Y == 0) ? 0.0 : std::atan2(static_cast<float>(axes.X), static_cast<float>(axes.Y));
  }
  virtual v2s32 getMousePos() override { return m_mouse_pos; }
  virtual void setMousePos(s32 x, s32 y) override { m_mouse_pos = v2s32(x, y); }

  virtual s32 getMouseWheel() override {
    s32 prev = m_mouse_wheel;
    m_mouse_wheel = 0;
    return prev;
  }

  virtual void clearWasKeyPressed() override { m_key_was_pressed.clear(); }
  virtual void clearWasKeyReleased() override { m_key_was_released.clear(); }
  void clearInput();

  virtual void step(float dtime) override;
  virtual void step_post_render() override;

  void simulateEvent(const SEvent &event) {
    if (event.EventType == EET_MOUSE_INPUT_EVENT) {
      // we need this call to trigger GUIEvents
      // e.g. for updating selected/hovered elements
      // in the inventory
      // BUT somehow only simulating with this call
      // does not trigger any mouse movement at all..
      guienv->postEventFromUser(event);
    }
    // .. which is why we need this second call
    // TODO is it possible to have all behaviors with one call?
    m_receiver->OnEvent(event);
  }

private:
  // Returns a vector with 2 elements in the set (-1, 0, 1) representing the joystick axes.
  virtual v2s32 getJoystickAxes() {
    return v2s32(
      static_cast<int>(m_key_is_down[keycache.key[KeyType::RIGHT]]) -
        static_cast<int>(m_key_is_down[keycache.key[KeyType::LEFT]])
      ,
      static_cast<int>(m_key_is_down[keycache.key[KeyType::FORWARD]]) -
        static_cast<int>(m_key_is_down[keycache.key[KeyType::BACKWARD]])
    );
  }

  void fill_observation(irr::video::IImage *image, float reward, std::map<std::string, float> aux);

  RenderingEngine *m_rendering_engine;

  detail::Channel m_chan;

  // Event receiver to simulate events
  MyEventReceiver *m_receiver = nullptr;

  // The state of the mouse wheel
  s32 m_mouse_wheel = 0;

  // The current state of keys
  KeyList m_key_is_down;

  // Like keyIsDown but only reset when that key is read
  KeyList m_key_was_down;

  // Whether a key has just been pressed
  KeyList m_key_was_pressed;

  // Whether a key has just been released
  KeyList m_key_was_released;

  // Mouse observables
  v2s32 m_mouse_pos;
  v2s32 m_mouse_speed;

  float m_movement_direction;

  bool m_is_first_loop = true;

  bool m_should_send_observation = false;
};

#pragma GCC diagnostic pop
