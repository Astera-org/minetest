#include "remoteinputhandler.h"
#include "IEventReceiver.h"

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

	mousepos[0] += 1000;
	mousepos[1] += 1000;
	infostream << "MOUSE: " << mousepos[0] << " " << mousepos[1];

	SEvent e;
	e.EventType = EET_MOUSE_INPUT_EVENT;
	e.MouseInput.Event = EMIE_MOUSE_MOVED;
	// where is the cursor now?
	e.MouseInput.X = mousepos[0];
	e.MouseInput.Y = mousepos[1];
	// which buttons are pressed?
	e.MouseInput.ButtonStates = 0;
	// shift / ctrl
	e.MouseInput.Shift = false;
	e.MouseInput.Control = false;
	simulateEvent(e);

	KeyPress newKeyCode;
	if (text == "W") {
		newKeyCode = keycache.key[KeyType::FORWARD];
	} else if (text == "S") {
		newKeyCode = keycache.key[KeyType::BACKWARD];
	} else if (text == "A") {
		newKeyCode = keycache.key[KeyType::LEFT];
	} else if (text == "D") {
		newKeyCode = keycache.key[KeyType::RIGHT];
	} else if (text == " ") {
		newKeyCode = keycache.key[KeyType::JUMP];
	}
	if (!keyIsDown[newKeyCode]) {
		keyWasPressed.set(newKeyCode);
	}
	keyIsDown.set(newKeyCode);
	keyWasDown.set(newKeyCode);
};
