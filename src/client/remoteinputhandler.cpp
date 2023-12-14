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

	::capnp::MallocMessageBuilder obs_prot;
	Observation::Builder obs_builder = obs_prot.initRoot<Observation>();
	obs_builder.setReward(1.0);
	obs_builder.initImage();
	auto image_builder = obs_builder.getImage();
	image_builder.setWidth(image->getDimension().Width);
	image_builder.setHeight(image->getDimension().Height);
	image_builder.setData(
			capnp::Data::Reader(reinterpret_cast<const uint8_t *>(image->getData()),
					image->getImageDataSizeInBytes()));

	auto capnData = capnp::messageToFlatArray(obs_prot);
	zmqpp::message obs_msg;
	obs_msg.add_raw(capnData.begin(), capnData.size() * sizeof(capnp::word));
	m_socket.send(obs_msg);
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

	// we don't model key release events, keys need to be re-pressed every step
	// there's only one place in the engine were keyRelease events are used, and 
	// it doesn't seem important.
	clearInput();

	KeyPress newKeyCode;

	for (auto keyEvent : action.getKeyEvents()) {
		newKeyCode = keycache.key[static_cast<int>(keyEvent)];
		if (!keyIsDown[newKeyCode]) {
			keyWasPressed.set(newKeyCode);
		}
		keyIsDown.set(newKeyCode);
		keyWasDown.set(newKeyCode);
	}
	mousespeed = v2s32(action.getMouseDx(), action.getMouseDy());
	// mousepos is reset to (WIDTH/2, HEIGHT/2) after every iteration of main game loop
	// unit is pixels, origin is top left corner, bounds is (0,0) to (WIDTH, HEIGHT)
	mousepos += mousespeed;
};

void RemoteInputHandler::clearInput()
{
	keyIsDown.clear();
	// keyWasDown.clear();
	keyWasPressed.clear();
	// keyWasReleased.clear();

	mouse_wheel = 0;
}
