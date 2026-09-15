// LaTeXture.cs
using Godot;
using System.IO;
using CSharpMath.SkiaSharp;
using CSharpMath.Rendering.FrontEnd;
using SkiaSharp;

[Tool]
public partial class LaTeXture : ImageTexture {
	public string LatexExpression = "";
	public float FontSize = 40f;
	public Color MathColor = new Color(0, 0, 0, 1);
	public bool AntiAliasing = true;
	public bool Fill = true;
	public bool ShowError = true;

	public float Width;
	public float Height;
	public float OffsetX;
	public float OffsetY;

	public void Render() {
		//GD.Print("[LaTeXture] Render() called.");
		//GD.Print($"[LaTeXture] Expression: '{LatexExpression}'");
		//GD.Print($"[LaTeXture] FontSize={FontSize} AntiAliasing={AntiAliasing} Fill={Fill} ShowError={ShowError}");
		//GD.Print($"[LaTeXture] MathColor: R={MathColor.R} G={MathColor.G} B={MathColor.B} A={MathColor.A}");

		if (string.IsNullOrWhiteSpace(LatexExpression)) {
			GD.PrintErr("[LaTeXture] LatexExpression is null or empty — aborting.");
			return;
		}

		var r = (byte)(255 * MathColor.R);
		var g = (byte)(255 * MathColor.G);
		var b = (byte)(255 * MathColor.B);
		var a = (byte)(255 * MathColor.A);

		var paintStyle = Fill ? PaintStyle.Fill : PaintStyle.Stroke;

		MathPainter painter;
		try {
			painter = new MathPainter {
				AntiAlias     = AntiAliasing,
				TextColor     = new SKColor(r, g, b, a),
				FontSize      = FontSize,
				LaTeX         = @"\raisebox{40mu}{}\raisebox{-40mu}{}" + LatexExpression + @"\:\raisebox{1mu}",
				DisplayErrorInline = ShowError,
				PaintStyle    = paintStyle,
			
			};
			//GD.Print("[LaTeXture] MathPainter created successfully.");
		} catch (System.Exception e) {
			GD.PrintErr($"[LaTeXture] MathPainter constructor threw: {e.Message}\n{e.StackTrace}");
			return;
		}

		try {
			var measure = painter.Measure();
			Width   = measure.Width;
			Height  = measure.Height;
			OffsetX = measure.X;
			OffsetY = measure.Y;
			//GD.Print($"[LaTeXture] Measure: W={Width} H={Height} X={OffsetX} Y={OffsetY}");

			if (Width <= 0 || Height <= 0) {
				GD.PrintErr($"[LaTeXture] Measure returned non-positive size — expression may be invalid.");
				return;
			}
		} catch (System.Exception e) {
			GD.PrintErr($"[LaTeXture] Measure() threw: {e.Message}\n{e.StackTrace}");
			return;
		}

		Stream png;
		try {
			png = painter.DrawAsStream();
			if (png == null) {
				GD.PrintErr("[LaTeXture] DrawAsStream() returned null.");
				return;
			}
			//GD.Print($"[LaTeXture] DrawAsStream() OK. Length={png.Length} Position={png.Position}");
		} catch (System.Exception e) {
			GD.PrintErr($"[LaTeXture] DrawAsStream() threw: {e.Message}\n{e.StackTrace}");
			return;
		}

		using (png) {
			png.Seek(0, SeekOrigin.Begin);
			//GD.Print($"[LaTeXture] Stream position after Seek: {png.Position}");

			byte[] pngBytes;
			using (var ms = new MemoryStream()) {
				png.CopyTo(ms);
				pngBytes = ms.ToArray();
			}

			//GD.Print($"[LaTeXture] PNG bytes: {pngBytes.Length}");
			if (pngBytes.Length == 0) {
				GD.PrintErr("[LaTeXture] PNG byte array is empty — nothing to load.");
				return;
			}

			var image = new Godot.Image();
			var err = image.LoadPngFromBuffer(pngBytes);
			if (err != Error.Ok) {
				GD.PrintErr($"[LaTeXture] LoadPngFromBuffer failed: {err}");
				return;
			}

			//GD.Print($"[LaTeXture] Image loaded: {image.GetWidth()}x{image.GetHeight()} format={image.GetFormat()}");

			if (image.GetWidth() == 0 || image.GetHeight() == 0) {
				GD.PrintErr("[LaTeXture] Loaded image has zero dimensions.");
				return;
			}

			SetImage(image);
			//GD.Print($"[LaTeXture] SetImage() done. Texture is now {GetWidth()}x{GetHeight()}.");
		}
	}
}