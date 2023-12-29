#include "gui/mainmenumanager.h"
#include "remoteclient.capnp.h"
#include "inputhandler.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>

class RemoteInputHandler : public InputHandler
{
public:
	RemoteInputHandler(const std::string &endpoint, RenderingEngine *rendering_engine,
			MyEventReceiver *receiver) :
			m_rendering_engine(rendering_engine),
            m_context(),
			m_socket(m_context, zmqpp::socket_type::reply), m_receiver(receiver)
	{
		infostream << "RemoteInputHandler: Binding to " << endpoint << std::endl;
		m_socket.bind(endpoint);
		// wait for client
		zmqpp::message message;
		m_socket.receive(message);
		std::string data;
		message >> data;
		kj::ArrayPtr<const capnp::word> words(reinterpret_cast<const capnp::word*>(data.data()), data.size() / sizeof(capnp::word));
		capnp::FlatArrayMessageReader reader(words);
		Action::Reader action = reader.getRoot<Action>();
		if (action.hasKeyEvents()){
			throw std::runtime_error("INVALID HANDSHAKE: Got key events in handshake");
		}
	}

	bool isDetached() const override { return true; }

	virtual bool isKeyDown(GameKeyType k) override { return keyIsDown[keycache.key[k]]; }
	virtual bool wasKeyDown(GameKeyType k) override
	{
		bool b = keyWasDown[keycache.key[k]];
		if (b)
			keyWasDown.unset(keycache.key[k]);
		return b;
	}
	virtual bool wasKeyPressed(GameKeyType k) override
	{
		return keyWasPressed[keycache.key[k]];
	}
	virtual bool wasKeyReleased(GameKeyType k) override
	{
		return keyWasReleased[keycache.key[k]];
	}
	virtual bool cancelPressed() override
	{
		return keyWasDown[keycache.key[KeyType::ESC]];
	}
	virtual float getMovementSpeed() override
	{
		bool f = keyIsDown[keycache.key[KeyType::FORWARD]],
			 b = keyIsDown[keycache.key[KeyType::BACKWARD]],
			 l = keyIsDown[keycache.key[KeyType::LEFT]],
			 r = keyIsDown[keycache.key[KeyType::RIGHT]];
		if (f || b || l || r) {
			// if contradictory keys pressed, stay still
			if (f && b && l && r)
				return 0.0f;
			else if (f && b && !l && !r)
				return 0.0f;
			else if (!f && !b && l && r)
				return 0.0f;
			return 1.0f; // If there is a keyboard event, assume maximum speed
		}
		return 0.0f;
	}
	virtual float getMovementDirection() override
	{
		float x = 0, z = 0;

		/* Check keyboard for input */
		if (keyIsDown[keycache.key[KeyType::FORWARD]])
			z += 1;
		if (keyIsDown[keycache.key[KeyType::BACKWARD]])
			z -= 1;
		if (keyIsDown[keycache.key[KeyType::RIGHT]])
			x += 1;
		if (keyIsDown[keycache.key[KeyType::LEFT]])
			x -= 1;

		if (x != 0 || z != 0) /* If there is a keyboard event, it takes priority */
			return atan2(x, z);
		return movementDirection;
	}
	virtual v2s32 getMousePos() override { return mousepos; }
	virtual void setMousePos(s32 x, s32 y) override { mousepos = v2s32(x, y); }

	virtual s32 getMouseWheel() override
	{
		s32 a = mouse_wheel;
		mouse_wheel = 0;
		return a;
	}

	virtual void clearWasKeyPressed() override { keyWasPressed.clear(); }
	virtual void clearWasKeyReleased() override { keyWasReleased.clear(); }
	void clearInput();

	virtual void step(float dtime) override;
	void simulateEvent(const SEvent &event)
	{
		// m_receiver->m_input_blocked = false;
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
		// m_receiver->m_input_blocked = true;
	}

private:
	RenderingEngine *m_rendering_engine;

	// zmq state
	zmqpp::context m_context;
	zmqpp::socket m_socket;

	// Event receiver to simulate events
	MyEventReceiver *m_receiver = nullptr;

	// Whether a GUI (inventory/menu) was open
	bool wasGuiOpen = false;

	// The state of the mouse wheel
	s32 mouse_wheel = 0;

	// The current state of keys
	KeyList keyIsDown;

	// Like keyIsDown but only reset when that key is read
	KeyList keyWasDown;

	// Whether a key has just been pressed
	KeyList keyWasPressed;

	// Whether a key has just been released
	KeyList keyWasReleased;

	// Mouse observables
	v2s32 mousepos;
	v2s32 mousespeed;

	// Player observables
	float movementSpeed;
	float movementDirection;
};
