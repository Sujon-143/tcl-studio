// LaTeX.cs
using Godot;

[Tool]
[GlobalClass]
public partial class LaTeX : BaseSprite2D {

	private string _latexExpression = "";
	[Export(PropertyHint.MultilineText)]
	public string LatexExpression {
		get => _latexExpression;
		set {
			////GD.Print($"[LaTeX] LatexExpression set to: '{value}'");
			_latexExpression = value;
			Render();
		}
	}

	private float _fontSize = 40f;
	[Export(PropertyHint.Range, "10,60,1,or_greater,or_lesser")]
	public float FontSize {
		get => _fontSize;
		set {
			////GD.Print($"[LaTeX] FontSize set to: {value}");
			_fontSize = value;
			Render();
		}
	}

	private Color _mathColor = new Color(0, 0, 0, 1);
	[Export]
	public Color MathColor {
		get => _mathColor;
		set {
			////GD.Print($"[LaTeX] MathColor set to: {value}");
			_mathColor = value;
			Render();
		}
	}

	private bool _antiAliasing = true;
	[Export]
	public bool AntiAliasing {
		get => _antiAliasing;
		set {
			////GD.Print($"[LaTeX] AntiAliasing set to: {value}");
			_antiAliasing = value;
			Render();
		}
	}

	private bool _fill = true;
	[Export]
	public bool Fill {
		get => _fill;
		set {
			////GD.Print($"[LaTeX] Fill set to: {value}");
			_fill = value;
			Render();
		}
	}

	private bool _showError = true;
	[Export]
	public bool ShowError {
		get => _showError;
		set {
			////GD.Print($"[LaTeX] ShowError set to: {value}");
			_showError = value;
			Render();
		}
	}

	public float Width;
	public float Height;
	public float OffsetX;
	public float OffsetY;

	private LaTeXture _texture;

	public void Render() {
		//GD.Print("[LaTeX] Render() called.");

		if (!IsInsideTree()) {
			////GD.Print("[LaTeX] Not inside tree yet — skipping.");
			return;
		}

		if (string.IsNullOrWhiteSpace(_latexExpression)) {
			////GD.Print("[LaTeX] LatexExpression is empty — skipping.");
			return;
		}

		if (_texture == null) {
			_texture = new LaTeXture();
			//GD.Print("[LaTeX] Created new LaTeXture instance.");
		}

		_texture.LatexExpression = _latexExpression;
		_texture.FontSize        = _fontSize;
		_texture.AntiAliasing    = _antiAliasing;
		_texture.Fill            = _fill;
		_texture.MathColor       = _mathColor;
		_texture.ShowError       = _showError;

		_texture.Render();

		if (_texture.GetWidth() == 0 || _texture.GetHeight() == 0) {
			//GD.PrintErr("[LaTeX] LaTeXture produced a 0x0 texture — not assigning.");
			return;
		}

		Texture  = _texture;
		Width    = _texture.Width;
		Height   = _texture.Height;
		OffsetX  = _texture.OffsetX;
		OffsetY  = _texture.OffsetY;

		//GD.Print($"[LaTeX] Texture assigned. Size: {_texture.GetWidth()}x{_texture.GetHeight()}");
		//GD.Print($"[LaTeX] Measure — W:{Width} H:{Height} OffX:{OffsetX} OffY:{OffsetY}");
	}

	public override void _Ready() {
		//GD.Print("[LaTeX] _Ready() called.");
		Render();
	}


}