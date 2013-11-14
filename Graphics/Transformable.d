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
module Dgame.Graphics.Transformable;

private {
	import std.math : isNaN;
	
	import derelict.opengl3.gl;
	
	import Dgame.Graphics.Moveable;
}

/**
 * Basic implementation for transformable objects.
 * 
 * Author: rschuett
 */
abstract class Transformable : Moveable {
private:
	short _rotAngle;
	float _zoom = 1f;

protected:
	int[2] _getAreaSize() const pure nothrow {
		return [0, 0];
	}
	
public:
	/**
	 * Reset the translation.
	 */
	override void resetTranslation() {
		super.resetTranslation();
		
		this.setRotation(0);
		this.setScale(1);
	}

	/**
	* Apply translation to the object.
	*/
	override void applyTranslation() const {
		super.applyTranslation();

		if (this._rotAngle != 0) {
			const int[2] area_size = this._getAreaSize();

			if (area_size[0] != 0 && area_size[1] != 0)
				glTranslatef(area_size[0] / 2, area_size[1] / 2, 0);

			glRotatef(this._rotAngle, 0f, 0f, 1f);

			if (area_size[0] != 0 && area_size[1] != 0)
				glTranslatef(-(area_size[0] / 2), -(area_size[1] / 2), 0);
		}

		if (!isNaN(this._zoom) && this._zoom != 1f)
			glScalef(this._zoom, this._zoom, 0f);
	}

final:
	/**
	 * Set a (new) rotation.
	 */
	void setRotation(short rotAngle) {
		this._rotAngle = rotAngle;
		
		if (this._rotAngle > 360 || this._rotAngle < -360)
			this._rotAngle = 0;
	}
	
	/**
	 * Increase/Decrease the rotation.
	 */
	void rotate(short rotAngle) {
		this._rotAngle += rotAngle;
	}
	
	/**
	 * Returns the current rotation.
	 */
	short getRotation() const pure nothrow {
		return this._rotAngle;
	}
	
	/**
	 * Set a new scale.
	 */
	void setScale(float zoom) {
		this._zoom = zoom;
	}
	
	/**
	 * Increase/Decrease the scale/zoom.
	 */
	void scale(float zoom) {
		if (isNaN(this._zoom))
			return this.setScale(zoom);
		
		this._zoom += zoom;
	}
	
	/**
	 * Returns the current scale/zoom.
	 */
	float getScale() const pure nothrow {
		return this._zoom;
	}
}