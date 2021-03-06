/*
 *******************************************************************************************
 * Dgame (a D game framework) - Copyright (c) Randy Schütt
 * 
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software.
 * 
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not claim
 *    that you wrote the original software. If you use this software in a product,
 *    an acknowledgment in the product documentation would be appreciated but is
 *    not required.
 * 
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 
 * 3. This notice may not be removed or altered from any source distribution.
 *******************************************************************************************
 */
module Dgame.Audio.Internal.core;

package {
	import derelict.openal.al;
	import derelict.ogg.ogg;
	import derelict.vorbis.vorbis;
	import derelict.vorbis.file;
	
	import Dgame.Internal.Log;
}

private:

struct AL {
static:
	ALCdevice* Device;
	ALCcontext* Context;
}

void _alError(string msg) {
	debug switch (alcGetError(AL.Device)) {
		case ALC_INVALID_DEVICE:
			Log.info("Invalid device");
			break;
		case ALC_INVALID_CONTEXT:
			Log.info("Invalid context");
			break;
		case ALC_INVALID_ENUM:
			Log.info("Invalid enum");
			break;
		case ALC_INVALID_VALUE:
			Log.info("Invalid value");
			break;
		case ALC_OUT_OF_MEMORY:
			Log.info("Out of memory");
			break;
		case ALC_NO_ERROR:
			Log.info("No error");
			break;
		default: break;
	}
	
	Log.error(msg);
}

static this() {
	// Init openAL
	debug Log.info("init openAL");
	
	DerelictAL.load();
	DerelictOgg.load();
	DerelictVorbis.load();
	DerelictVorbisFile.load();
	
	AL.Device = alcOpenDevice(null);
	if (AL.Device is null)
		_alError("Device is null");
	
	AL.Context = alcCreateContext(AL.Device, null);
	if (AL.Context is null)
		_alError("Context is null.");
	
	alcMakeContextCurrent(AL.Context);
}

static ~this() {
	alcMakeContextCurrent(null);
	alcDestroyContext(AL.Context);
	alcCloseDevice(AL.Device);
	
	DerelictVorbis.unload();
	DerelictVorbisFile.unload();
	DerelictOgg.unload();
	DerelictAL.unload();
}

