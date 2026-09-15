using Godot;

[Tool]
public partial class BaseSprite2D : Sprite2D
{
    [ExportCategory("Appearance Animations")]

    private float _baseScale = 1.0f;

    [Export]
    public float BaseScale
    {
        get => _baseScale;
        set
        {
            _baseScale = value;
            Scale = _baseScale * Vector2.One;
        }
    }

    private float _popupProgress = 0.0f;

    [Export(PropertyHint.Range, "0,1.0,0.01")]
    public float PopupProgress
    {
        get => _popupProgress;
        set
        {
            _popupProgress = value;
            var target = this;

            GD.Print("applying: ", value);

            if (_popupProgress <= 0.05f)
            {
                target.Hide();
                return;
            }
            else
            {
                target.Show();
            }

            target.Scale = _baseScale * Vector2.One * EaseOut(TransBack(value), value);
        }
    }

    private float TransBack(float t)
    {
        float c1 = 1.70158f;
        float c3 = c1 + 1f;
        return 1f + c3 * Mathf.Pow(t - 1f, 3f) + c1 * Mathf.Pow(t - 1f, 2f);
    }

    private float EaseOut(float overshoot, float t)
    {
        return 1f - Mathf.Pow(1f - t, 3f) + overshoot * Mathf.Sin(t * Mathf.Pi) * 0.3f;
    }
}