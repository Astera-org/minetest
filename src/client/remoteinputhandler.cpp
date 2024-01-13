#include "remoteinputhandler.h"
#include "IEventReceiver.h"
#include "client/keycode.h"
#include "client/keys.h"
#include "clientiface.h"
#include "hud.h"
#include "irr_v2d.h"
#include "remoteclient.capnp.h"

void RemoteInputHandler::step(float dtime)
{
	// send current observation
	irr::video::IVideoDriver *driver = m_rendering_engine->get_video_driver();
	irr::video::IImage *image;
	if (m_rendering_engine->headless) {
		image = m_rendering_engine->get_screenshot();
	} else {
		image = driver->createScreenShot(video::ECF_R8G8B8);
	}

	::capnp::MallocMessageBuilder obs_prot;
	Observation::Builder obs_builder = obs_prot.initRoot<Observation>();

	// parse reward from hud
	// during game startup, the hud is not yet initialized, so there'll be no reward
	// for the first 1-2 steps
	assert(m_player && "Player is null");
	for (u32 i = 0; i < m_player->maxHudId(); ++i) {
		auto hudElement = m_player->getHud(i);
		std::cout << hudElement->name << '\n';
		if (hudElement->name == "reward") {
			// parse 'Reward: <reward>' from hud
			std::string rewardString = hudElement->text;
			rewardString.erase(0, 8);
			obs_builder.setReward(stof(rewardString));
			break;
		}
	}

	obs_builder.initImage();
	auto image_builder = obs_builder.getImage();
	// draw() is called after step(), so there won't be an image on the first step
	if (image) {
		image_builder.setWidth(image->getDimension().Width);
		image_builder.setHeight(image->getDimension().Height);
		image_builder.setData(
				capnp::Data::Reader(reinterpret_cast<const uint8_t *>(image->getData()),
						image->getImageDataSizeInBytes()));
	} else {
		image_builder.setWidth(0);
		image_builder.setHeight(0);
		image_builder.setData(capnp::Data::Reader());
	}

	auto capnData = capnp::messageToFlatArray(obs_prot);
	zmqpp::message obs_msg;
	obs_msg.add_raw(capnData.begin(), capnData.size() * sizeof(capnp::word));
	m_socket.send(obs_msg);

	if (image)
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
