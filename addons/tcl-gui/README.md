# tcl-gui add-on

Hand-drawn, bindable 2D GUI controls for tcl-studio, plus an inspector plugin
that turns a control's binding target into a dropdown of the real properties and
methods on the chosen node.

## Why it exists

Scientific and mathematical videos often need on-screen controls — a slider that
drives a parameter, a toggle that switches a value, a meter that reflects live
state. Godot's built-in `Control` nodes look like default UI, and wiring a
control to a scene property usually means typing a property name as a free string
with no validation. This add-on provides styled controls drawn for presentation,
a small binding model, and editor pickers that remove the guesswork from those
string references.

## Controls

All controls extend `GuiElement2D`, which provides a shared rounded/shadowed
look, smoothed hover and press feedback, an optional value label, and the
`bind_to` array.

| Class | File | Direction | Notes |
| --- | --- | --- | --- |
| `GuiElement2D` | `gui_element_2d.gd` | — | Base class: styling, binding, hover/press state. |
| `Slider2D` | `slider_2d.gd` | Out | Horizontal slider emitting a float in `[min_value, max_value]`. |
| `RangeSlider` | `range_slider.gd` | Out | Two-handle slider for a min/max range. |
| `Toggle2D` | `toggle_2d.gd` | Out | On/off switch. |
| `Button2D` | `button_2d.gd` | Out | Momentary button, typically bound with `call_as_method`. |
| `Stepper` | `stepper.gd` | Out | Increment/decrement control. |
| `CircularSlider2D` | `circular_slider_2d.gd` | Out | Radial slider for angle-like values. |
| `LevelMeter2D` | `level_meter_2d.gd` | In | Reads a source node's property each frame and shows it as a bar; can also forward the value onward via `bind_to`. |

## Binding model

A control's `bind_to` is an `Array[BindTarget]`, so one control can drive several
targets at once. Each `BindTarget` (`bind_target.gd`) describes:

- `target_node` — the node to drive, resolved relative to the control.
- `target_property` — the property to set, or the method to call.
- `call_as_method` — treat `target_property` as a method and pass the control's
  value as its single argument (used for buttons and custom logic).
- `enable_remap` with `remap_in_min/max` and `remap_out_min/max` — optional
  linear remap of the control's raw value before applying it.

`LevelMeter2D` reads instead of writes: it polls `source_property` on
`source_node` every frame, with smoothing and optional peak hold.

## Editor pickers

The plugin registers an `EditorInspectorPlugin`
(`bind_target_inspector_plugin.gd`) that replaces free-typed strings with
dropdowns:

- On a `BindTarget`, `target_property` renders as a dropdown built from
  `target_node`'s actual properties and methods.
- On a `LevelMeter2D`, `source_property` renders as a dropdown built from
  `source_node`'s properties.

## Usage

1. Enable **tcl-gui** from **Project > Project Settings > Plugins**.
2. Add a control (for example `Slider2D`) to a 2D scene.
3. Expand its **Binding** group and add a `BindTarget` entry.
4. Set `target_node` to the node to drive; pick `target_property` from the
   dropdown.
5. Optionally enable the remap to scale the value into the target's range.

## Files

| File | Purpose |
| --- | --- |
| `plugin.cfg` | Plugin manifest. |
| `plugin.gd` | Registers the inspector plugin with the editor. |
| `bind_target.gd` | The `BindTarget` resource and its `apply()` logic. |
| `bind_target_inspector_plugin.gd` | Routes pickers for `BindTarget` and `LevelMeter2D`. |
| `bind_target_property_picker.gd` | Property/method dropdown for `BindTarget`. |
| `source_property_picker.gd` | Property dropdown for `LevelMeter2D`. |
| `gui_element_2d.gd` | Base class for all controls. |
| `slider_2d.gd`, `range_slider.gd`, `toggle_2d.gd`, `button_2d.gd`, `stepper.gd`, `circular_slider_2d.gd`, `level_meter_2d.gd` | The individual controls. |
