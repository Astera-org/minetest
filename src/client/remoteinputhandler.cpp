#include "remoteinputhandler.h"
#include "IEventReceiver.h"
#include "client/keycode.h"
#include "client/keys.h"
#include "clientiface.h"
#include "irr_v2d.h"
#include "remoteclient.capnp.h"

void RemoteInputHandler::step(float dtime)
{
	// send current observation
	irr::video::IVideoDriver *driver = m_rendering_engine->get_video_driver();
	irr::video::IImage *const image = driver->createScreenShot(video::ECF_R8G8B8);
	zmqpp::message image_msg;
	image_msg.add_raw(image->getData(), image->getImageDataSizeInBytes());
	m_socket.send(image_msg);
	image->drop();

	// receive next key
	zmqpp::message message;
	m_socket.receive(message);

	std::string data;
	message >> data;
	kj::ArrayPtr<const capnp::word> words(
			reinterpret_cast<const capnp::word *>(data.data()),
			data.size() / sizeof(capnp::word));

	capnp::FlatArrayMessageReader reader(words);
	Action::Reader action = reader.getRoot<Action>();
	infostream << "Action ASDF: " << action.toString().flatten().cStr() << std::endl;

	clearInput();

	KeyPress newKeyCode;

	for (auto keyEvent : action.getKeyEvents()) {
		switch (keyEvent) {
		case KeyPressType::Key::FORWARD:
			newKeyCode = keycache.key[KeyType::FORWARD];
			break;
		case KeyPressType::Key::BACKWARD:
			newKeyCode = keycache.key[KeyType::BACKWARD];
			break;
		case KeyPressType::Key::LEFT:
			newKeyCode = keycache.key[KeyType::LEFT];
			break;
		case KeyPressType::Key::RIGHT:
			newKeyCode = keycache.key[KeyType::RIGHT];
			break;
		case KeyPressType::Key::JUMP:
			newKeyCode = keycache.key[KeyType::JUMP];
			break;
		default:
			break;
		}
		if (!keyIsDown[newKeyCode]) {
			keyWasPressed.set(newKeyCode);
		}
		keyIsDown.set(newKeyCode);
		keyWasDown.set(newKeyCode);
	}
	mousespeed = v2s32(action.getMouseDx(), action.getMouseDy());
	// mousepos is reset to (WIDTH/2, HEIGHT/2) after every iteration of main game loop
	// unit is (scaled) pixels
	mousepos += mousespeed;
};
