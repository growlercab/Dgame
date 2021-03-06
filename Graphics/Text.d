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
module Dgame.Graphics.Text;

private {
	import std.string : format, toStringz;
	
	import derelict.opengl3.gl;
	import derelict.sdl2.sdl; // because of SDL_Surface and SDL_FreeSurface
	import derelict.sdl2.ttf;
	
	import Dgame.Internal.Log;
	import Dgame.Graphics.Drawable;
	import Dgame.Graphics.Transformable;
	import Dgame.Graphics.Color;
	import Dgame.Graphics.Font;
	import Dgame.Graphics.Texture;
	import Dgame.Graphics.Shape;
	import Dgame.Graphics.Blend;
	import Dgame.Math.Vector2;
	import Dgame.Math.Rect;
	import Dgame.System.VertexRenderer;
}

private Font*[] _FontFinalizer;

static ~this() {
	debug Log.info("Text: Finalize Font");
	
	for (size_t i = 0; i < _FontFinalizer.length; ++i) {
		if (_FontFinalizer[i] !is null) {
			debug Log.info(" -> Finalize font i = %d, ptr = %x", i, _FontFinalizer[i].ptr);
			_FontFinalizer[i].free();
		}
	}
	
	_FontFinalizer = null;
	
	debug Log.info("Font finalized");
}

/**
 * Text defines a graphical 2D text, that can be drawn on screen.
 *	- The default foreground color is <code>Color.Black</code>
 *	- The default background color is <code>Color.White</code>
 *
 * Author: rschuett
 */
class Text : Transformable, Drawable, Blendable {
protected:
	string _text;
	bool _needUpdate;
	
	Color _fg = Color.Black;
	Color _bg = Color.White;
	
	Font _font;
	Texture _tex;
	Blend _blend;
	
private:
	void _storePixel(SDL_Surface* rhs, Texture.Format fmt) in {
		assert(this._tex !is null, "No Texture!");
		assert(rhs !is null, "No Surface!");
	} body {
		this._tex.loadFromMemory(rhs.pixels,
		                         cast(ushort) rhs.w, cast(ushort) rhs.h,
		                         rhs.format.BitsPerPixel, fmt);
	}
	
	void _update() in {
		assert(this._tex !is null, "No Texture!");
	} body {
		this._needUpdate = false;
		
		SDL_Surface* srfc;
		scope(exit) SDL_FreeSurface(srfc);
		
		immutable char* cstr = toStringz(this._text);

		SDL_Color fg = void;
		SDL_Color bg = void;

		this._fg.transferTo(&fg);
		this._bg.transferTo(&bg);
		
		const Font.Mode fmode = this._font.getMode();
		
		final switch (fmode) {
			case Font.Mode.Solid:
				srfc = TTF_RenderUTF8_Solid(this._font.ptr, cstr, fg);
				break;
			case Font.Mode.Shaded:
				srfc = TTF_RenderUTF8_Shaded(this._font.ptr, cstr, fg, bg);
				break;
			case Font.Mode.Blended:
				srfc = TTF_RenderUTF8_Blended(this._font.ptr, cstr, fg);
				break;
		}
		
		enforce(srfc !is null, "Surface is null.");
		
		if (fmode != Font.Mode.Blended) {
			/// Adapt PixelFormat
			SDL_PixelFormat fmt;
			fmt.BitsPerPixel = 24;
			
			SDL_Surface* opt = SDL_ConvertSurface(srfc, &fmt, 0);
			scope(exit) SDL_FreeSurface(opt);
			
			enforce(opt !is null, "Optimized is null.");
			enforce(opt.pixels !is null, "Optimized pixels is null.");
			
			Texture.Format t_fmt = Texture.Format.None;
			if (opt.format.Rmask != 0x000000ff)
				t_fmt = opt.format.BitsPerPixel == 24 ? Texture.Format.BGR : Texture.Format.BGRA;
			
			this._storePixel(opt, t_fmt);
		} else {
			Texture.Format t_fmt = Texture.Format.None;
			if (srfc.format.Rmask != 0x000000ff)
				t_fmt = srfc.format.BitsPerPixel == 24 ? Texture.Format.BGR : Texture.Format.BGRA;
			
			this._storePixel(srfc, t_fmt);
		}
	}
	
protected:
	void _render() in {
		assert(this._tex !is null, "No valid Texture.");
	} body {
		glPushMatrix();
		scope(exit) glPopMatrix();
		
		super._applyTranslation();
		
		if (this._needUpdate)
			this._update();

		if (!glIsEnabled(GL_TEXTURE_2D))
			glEnable(GL_TEXTURE_2D);
		
		glPushAttrib(GL_CURRENT_BIT | GL_COLOR_BUFFER_BIT);
		scope(exit) glPopAttrib();

		float dx = 0f;
		float dy = 0f;
		float dw = this._tex.width;
		float dh = this._tex.height;

		float[12] vertices = [
			dx,      dy,      0f,
			dx + dw, dy,      0f,
			dx + dw, dy + dh, 0f,
			dx,      dy + dh, 0f
		];

		float[8] texCoords = [0f, 0f, 1f, 0f, 1f, 1f, 0f, 1f];

		VertexRenderer.pointTo(Target.Vertex, &vertices[0]);
		VertexRenderer.pointTo(Target.TexCoords, &texCoords[0]);
		
		scope(exit) {
			VertexRenderer.disableAllStates();
			this._tex.unbind();
		}
		
		this._tex.bind();

		if (this._blend !is null)
			this._blend.applyBlending();
		
		VertexRenderer.drawArrays(Shape.Type.TriangleFan, vertices.length);
	}

public:
	/**
	 * CTor
	 */
	this(ref Font font, string text = null) {
		this.replaceFont(font);
		
		this._text = text;
		this._needUpdate = true;
		this._tex = new Texture();
	}
	
	/**
	 * CTor: Rvalue version
	 */
	this(Font font, string text = null) {
		this(font, text);
	}

	/**
	 * Calculate, store and return the center point.
	 */
	override ref const(Vector2s) calculateCenter() pure nothrow {
		if (this._tex is null)
			return super.getCenter();

		super.setCenter(this._tex.width / 2, this._tex.height / 2);

		return super.getCenter();
	}

	/**
	 * Check whether the bounding box of this Text collide
	 * with the bounding box of another Text
	 */
	bool collideWith(const Text rhs) const {
		return this.collideWith(rhs.getBoundingBox());
	}
	
	/**
	 * Check whether the bounding box of this Sprite collide
	 * with the given Rect
	 */
	bool collideWith(ref const FloatRect rect) const {
		return this.getBoundingBox().intersects(rect);
	}
	
	/**
	 * Rvalue version
	 */
	bool collideWith(const FloatRect rect) const {
		return this.collideWith(rect);
	}
	
final:
	/**
	 * Set (or reset) the current Blend instance.
	 */
	void setBlend(Blend blend) pure nothrow {
		this._blend = blend;
	}

	/**
	 * Returns the current Blend instance, or null.
	 */
	inout(Blend) getBlend() inout pure nothrow {
		return this._blend;
	}

	/**
	 * Returns the bounding box, the area which will be drawn on the screen.
	 */
	FloatRect getBoundingBox() const pure nothrow in {
		assert(this._tex !is null);
	} body {
		return FloatRect(super.getPosition(), this._tex.width, this._tex.height);
	}
	
	/**
	 * Returns the width of the Text Texture
	 */
	@property
	ushort width() const pure nothrow {
		return this._tex !is null ? this._tex.width : 0;
	}
	
	/**
	 * Returns the height of the Text Texture
	 */
	@property
	ushort height() const pure nothrow {
		return this._tex !is null ? this._tex.height : 0;
	}

	/**
	 * Replace the current Font.
	 */
	void replaceFont(ref Font font) {
		this._font = font;
		_FontFinalizer ~= &this._font;
		
		this._needUpdate = true;
	}
	
	/**
	 * Rvalue version
	 */
	void replaceFont(Font font) {
		this.replaceFont(font);
	}
	
	/**
	 * Get the image containing the rendered characters.
	 */
	inout(Texture) getTexture() inout pure nothrow {
		return this._tex;
	}
	
	/**
	 * Returns the current Font object.
	 */
	ref inout(Font) getFont() inout pure nothrow {
		return this._font;
	}
	
	/**
	 * Activate an update.
	 * The current image will be updated.
	 * In most cases, this happens automatically,
	 * but sometimes it is usefull.
	 */
	void forceUpdate() pure nothrow {
		this._needUpdate = true;
	}
	
	/**
	 * Format a given string and draw it then on the image
	 */
	void format(Args...)(string text, Args args) {
		string formated = .format(text, args);
		
		if (formated != this._text) {
			this._text = formated;
			this._needUpdate = true;
		}
	}
	
	/**
	 * Replace the current string.
	 * 
	 * Examples:
	 * ---
	 * Font fnt = new Font("samples/font/arial.ttf", 12);
	 * Text t = new Text(font);
	 * t("My new string");
	 * ---
	 */
	void opCall(string text) pure nothrow {
		if (text != this._text) {
			this._text = text;
			this._needUpdate = true;
		}
	}
	
	/**
	 * Replace the current string.
	 * 
	 * Examples:
	 * ---
	 * Font fnt = new Font("samples/font/arial.ttf", 12);
	 * Text t1 = new Text(font);
	 * Text t2 = new Text(font);
	 * t1("My new string");
	 * t2(t1); // now both t's draw 'My new string' on screen.
	 * ---
	 */
	void opCall(ref const Text t) pure nothrow {
		return this.opCall(t.getString());
	}
	
	/**
	 * Concatenate the current string with another.
	 *
	 * Examples:
	 * ---
	 * Font fnt = new Font("samples/font/arial.ttf", 12);
	 * Text t = new Text(font);
	 * t("My new string");
	 * t ~= "is great!"; // t draws now 'My new string is great' on screen.
	 * ---
	 * The example above is the same as if you do:
	 * ---
	 * t += "is great!";
	 * ---
	 * Both operators (~ and +) are allowed.
	 */
	ref Text opBinary(string op)(string text) pure nothrow
		if (op == "~" || op == "+")
	{
		this._text ~= text;
		this._needUpdate = true;
		
		return this;
	}
	
	/**
	 * Concatenate the current string with another.
	 */
	ref Text opBinary(string op)(ref const Text t) pure nothrow 
		if (op == "~" || op == "+")
	{
		return this.opBinary!(op)(t.getString());
	}
	
	/**
	 * Returns the current string.
	 */
	string getString() const pure nothrow {
		return this._text;
	}
	
	/**
	 * Set the (foreground) color.
	 */
	void setColor(ref const Color col) {
		this._needUpdate = true;
		this._fg = col;
	}
	
	/**
	 * Rvalue version
	 */
	void setColor(const Color col) {
		this.setColor(col);
	}
	
	/**
	 * Returns the (foreground) color.
	 */
	ref const(Color) getColor() const pure nothrow {
		return this._fg;
	}
	
	/**
	 * Set the background color.
	 * Only needed if your Font.Mode is not Font.Mode.Solid.
	 */
	void setBackgroundColor(ref const Color col) {
		this._needUpdate = true;
		this._bg = col;
	}
	
	/**
	 * Rvalue version
	 */
	void setBackgroundColor(const Color col) {
		this.setBackgroundColor(col);
	}
	
	/**
	 * Returns the background color.
	 */
	ref const(Color) getBackgroundColor() const pure nothrow {
		return this._bg;
	}
}