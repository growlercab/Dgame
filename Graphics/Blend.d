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
module Dgame.Graphics.Blend;

private {
	import derelict.opengl3.gl;
	
	import Dgame.Graphics.Color;
}

/**
 * Enable blending
 */
interface Blendable {
	/**
	 * Set (or reset) the current Blend instance.
	 */
	void setBlend(Blend blend) pure nothrow;
	/**
	 * Returns the current Blend instance, or null.
	 */
	inout(Blend) getBlend() inout pure nothrow;
}

/**
 * The Blend class. If you want that a blendable object get some blend, 
 * create an instance of this class and give it to your blendable.
 *
 * Author: rschuett
 */
class Blend {
	/**
	 * Supported BlendModes
	 */
	enum Mode : ubyte {
		None,      /// No blending.
		Alpha,     /// Pixel = Src * a + Dest * (1 - a)
		Add,       /// Pixel = Src + Dest
		Multiply   /// Pixel = Src * Dest
	}
	
private:
	Mode _mode;
	Color _color;
	bool _isBlendColor;
	
public:
	/**
	 * Apply the blending
	 */
	void applyBlending() const {
		this.enable(true);

		if (this._isBlendColor) {
			const float[4] col = this._color.asGLColor();
			
			version(all)
				glBlendColor(col[0], col[1], col[2], col[3]);
			else
				glColor4f(col[0], col[1], col[2], col[3]);
		}
		
		final switch (this._mode) {
			case Mode.Alpha: // Alpha blending
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				break;
			case Mode.Add: // Additive blending
				glBlendFunc(GL_SRC_ALPHA, GL_ONE);
				break;
			case Mode.Multiply: // Multiplicative blending
				glBlendFunc(GL_DST_COLOR, GL_ZERO);
				break;
			case Mode.None: // No blending
				glBlendFunc(GL_ONE, GL_ZERO);
				break;
		}
	}
	
final:
	/**
	 * CTor
	 */
	this(Mode mode) {
		this.setBlendMode(mode);
	}

	/**
	 * CTor
	 */
	this(Mode mode, ref const Color col) {
		this(mode);

		this.setBlendColor(col);
	}

	/**
	 * Rvalue version
	 */
	this(Mode mode, const Color col) {
		this(mode, col);
	}
	
	/**
	 * Enable or Disable blending
	 */
	void enable(bool enable) const {
		const bool isEnabled = glIsEnabled(GL_BLEND) == GL_TRUE;

		if (enable && !isEnabled)
			glEnable(GL_BLEND);
		else if (!enable && isEnabled)
			glDisable(GL_BLEND);
	}
	
	/**
	 * Activate or deactivate the using of the blend color.
	 */
	void enableColor(bool enable) pure nothrow {
		this._isBlendColor = enable;
	}

	/**
	 * Set the Blendmode.
	 */
	void setBlendMode(Mode mode) pure nothrow {
		this._mode = mode;
	}
	
	/**
	 * Returns the current Blendmode.
	 */
	Mode getBlendMode() const pure nothrow {
		return this._mode;
	}
	
	/**
	 * Set the Blend Color.
	 */
	void setBlendColor(ref const Color col) pure nothrow {
		this._isBlendColor = true;
		this._color = col;
	}
	
	/**
	 * Rvalue version
	 */
	void setBlendColor(const Color col) pure nothrow {
		this.setBlendColor(col);
	}
	
	/**
	 * Returns the current Blend Color.
	 */
	ref const(Color) getBlendColor() const pure nothrow {
		return this._color;
	}
}