#include "remoteinputhandler.h"
#include "IEventReceiver.h"
#include "irr_v2d.h"

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
	std::string text;
	message >> text;

	clearInput();



	KeyPress newKeyCode;
	if (text == "W") {
		newKeyCode = keycache.key[KeyType::FORWARD];
	} else if (text == "S") {
		newKeyCode = keycache.key[KeyType::BACKWARD];
	} else if (text == "A") {
		newKeyCode = keycache.key[KeyType::LEFT];
	} else if (text == "D") {
		newKeyCode = keycache.key[KeyType::RIGHT];
	} else if (text == "SPACE") {
		newKeyCode = keycache.key[KeyType::JUMP];
	}

	mousespeed = v2s32(0, 0);
	if (text == "UP") {
		mousespeed.Y = -20;
	} else if (text == "DOWN") {
		mousespeed.Y = 20;
	} else if (text == "LEFT") {
		mousespeed.X = -20;
	} else if (text == "RIGHT") {
		mousespeed.X = 20;
	}
	// mousepos is reset to (WIDTH/2, HEIGHT/2) after every iteration of main game loop
	// unit is (scaled) pixels
	mousepos += mousespeed;

	if (!keyIsDown[newKeyCode]) {
		keyWasPressed.set(newKeyCode);
	}
	keyIsDown.set(newKeyCode);
	keyWasDown.set(newKeyCode);
};
