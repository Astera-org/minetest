/*
Minetest
Copyright (C) 2010-2013 celeron55, Perttu Ahola <celeron55@gmail.com>
Copyright (C) 2017 nerzhul, Loic Blot <loic.blot@unix-experience.fr>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#pragma once

#include <vector>
#include <memory>
#include <string>
#include "IImage.h"
#include "irrlichttypes_extrabloated.h"
#include "debug.h"
#include "client/render/core.h"
// include the shadow mapper classes too
#include "client/shadows/dynamicshadowsrender.h"

struct VideoDriverInfo {
	std::string name;
	std::string friendly_name;
};

class ITextureSource;
class Camera;
class Client;
class LocalPlayer;
class Hud;
class Minimap;

class RenderingCore;

class RenderingEngine
{
public:
	static const video::SColor MENU_SKY_COLOR;
	static const float BASE_BLOOM_STRENGTH;

	RenderingEngine(IEventReceiver *eventReceiver);
	~RenderingEngine();

	void setResizable(bool resize);

	video::IVideoDriver *getVideoDriver() { return driver; }

	static const VideoDriverInfo &getVideoDriverInfo(irr::video::E_DRIVER_TYPE type);
	static float getDisplayDensity();

	bool setupTopLevelWindow();
	bool setWindowIcon();
	static bool print_video_modes();
	void cleanupMeshCache();

	void removeMesh(const scene::IMesh* mesh);

	/**
	 * This takes 3d_mode into account - side-by-side will return a
	 * halved horizontal size.
	 *
	 * @return "window" size
	 */
	static v2u32 getWindowSize()
	{
		sanity_check(s_singleton);
		return s_singleton->_getWindowSize();
	}

	io::IFileSystem *get_filesystem()
	{
		return m_device->getFileSystem();
	}

	static video::IVideoDriver *get_video_driver()
	{
		sanity_check(s_singleton && s_singleton->m_device);
		return s_singleton->m_device->getVideoDriver();
	}

	scene::ISceneManager *get_scene_manager()
	{
		return m_device->getSceneManager();
	}

	static irr::IrrlichtDevice *get_raw_device()
	{
		sanity_check(s_singleton && s_singleton->m_device);
		return s_singleton->m_device;
	}

	u32 get_timer_time()
	{
		return m_device->getTimer()->getTime();
	}

	gui::IGUIEnvironment *get_gui_env()
	{
		return m_device->getGUIEnvironment();
	}

	void draw_load_screen(const std::wstring &text,
			gui::IGUIEnvironment *guienv, ITextureSource *tsrc,
			float dtime = 0, int percent = 0, bool sky = true);

	void draw_scene(video::SColor skycolor, bool show_hud,
			bool show_minimap, bool draw_wield_tool, bool draw_crosshair);

	void initialize(Client *client, Hud *hud);
	void finalize();

	bool run()
	{
		return m_device->run();
	}

	// FIXME: this is still global when it shouldn't be
	static ShadowRenderer *get_shadow_renderer()
	{
		if (s_singleton && s_singleton->core)
			return s_singleton->core->get_shadow_renderer();
		return nullptr;
	}
	static std::vector<irr::video::E_DRIVER_TYPE> getSupportedVideoDrivers();
	irr::video::IImage *get_screenshot();

	static void autosaveScreensizeAndCo(
			const irr::core::dimension2d<u32> initial_screen_size,
			const bool initial_window_maximized);

	static bool shouldRender()
	{
		// On Android, pause rendering while the app is in background (generally not visible).
		// Don't do this on desktop because windows can be partially visible.
#ifdef __ANDROID__
		return get_raw_device()->isWindowActive();
#else
		return true;
#endif
	};

private:
	v2u32 _getWindowSize() const;

	std::unique_ptr<RenderingCore> core;
	irr::IrrlichtDevice *m_device = nullptr;
	irr::video::IVideoDriver *driver;
	static RenderingEngine *s_singleton;
};
