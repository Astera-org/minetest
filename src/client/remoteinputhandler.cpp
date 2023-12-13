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

	::capnp::MallocMessageBuilder image_proto;
	Image::Builder image_builder = image_proto.initRoot<Image>();
	image_builder.setWidth(image->getDimension().Width);
	image_builder.setHeight(image->getDimension().Height);
	image_builder.setData(
			capnp::Data::Reader(reinterpret_cast<const uint8_t *>(image->getData()),
					image->getImageDataSizeInBytes()));

	auto capnData = capnp::messageToFlatArray(image_proto);
	zmqpp::message image_msg;
	image_msg.add_raw(capnData.begin(), capnData.size() * sizeof(capnp::word));
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
