defmodule Image.Text do
  @moduledoc """
  Functions for the creation of images from text.

  """

  alias Vix.Vips.Image, as: Vimage
  alias Vix.Vips.Operation
  alias Image.Options

  @doc """
  Create a new image from the provided text and
  formatting options.

  `new_from_string/2` creates an image with the
  following steps:

  * Render the text
  * Add an optional background color
  * Expand the background according to the required padding

  The text can be rendered as a positive (the default)
  in which an image of the provided string is rendered
  in the provided font, weight, size, fill color and
  stroke color.

  It can also be rendered transparently in which case
  a background color is required against which the
  transparent text can be composed. If not provided,
  the background color will be black.

  After rendering the text and composing it against
  the (optional) background, the background can
  be expanded to provide some padding between the
  text and any base image onto which it is later
  composed.  The default no padding.

  ### Arguments

  * `string` is any string. The string will be
    HTML-escapeed to avoid malicious code injection. If you
    are completely confident that the text is safe then
    you can pass it by calling with `Phoenix.HTML.raw/1`
    on the string first.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:font` is any font recognised on the host system.
    The default is"Helvetica".

  * `:font_size` is an integer font size in pixels. The
    dfault is `50`.

  * `:text_fill_color` is the fill color of the text.
    The default is "white". If set to `:transparent` then
    the text will be rendered transparently against
    a background. A black background will be forced if a
    `:background_color` is not provided

  * `:text_stroke_color` is the color of the outline
    of each character in the string. The default is "none".

  * `:text_stroke_width` is the integer width in
    pixels of the outline of each character in the string.
    The default is `1`.

  * `:font_weight` is the [font weight](https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight).
    The alternatives `:normal`, `:bold`, `:lighter`, `:bolder`,
    or an integer between `1` and `1_000`. The default is `:normal`
    which is equivalent to `400`.

  * `:background_color` is the background fill color behind
    the text. The default is `:none` which indicates no
    background. Note that if

  * `:background_stroke` is the colour of the outline
    of the background. The default is "none",

  * `:background_stroke_width` is the integer size in pixels
    of the background border. The default is `1`.

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  * `:padding` is the padding in pixels between the
    text and the edge of the background. THe default is `0`,

  ### Returns

  * `{:ok, image}` or

  * `{:error, reason}`

  ### Notes

  * There is no text wrapping, justification or kerning
    applied. This means this function is not a general
    purpose text layout function and is suitable mostly
    for overlaying text for emphasis over another image.

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec new_from_string(Phoenix.HTML.safe() | String.t(), Keyword.t()) :: {:ok, Vimage.t()} | {:error, Image.error_message()}
  def new_from_string(string, options \\ []) when is_list(options) do
    with {:ok, options} <- Options.Text.validate_options(options),
         {:ok, string} <- escape_html_text(string),
         {:ok, text_layer} <- text(string, options),
         {:ok, text_with_background} <- add_background(text_layer, options),
         {:ok, text_with_padding} <- add_background_padding(text_with_background, options) do
      add_background_border(text_with_padding, options)
    end
  end

  @doc """
  Create a new image from the provided text and
  formatting options returning an image or raising
  an exception.

  `new_from_string!/2` creates an image with the
  following steps:

  * Render the text
  * Add an optional background color
  * Expand the background according to the required padding

  The text can be rendered as a positive (the default)
  in which an image of the provided string is rendered
  in the provided font, weight, size, fill color and
  stroke color.

  It can also be rendered transparently in which case
  a background color is required against which the
  transparent text can be composed. If not provided,
  the background color will be black.

  After rendering the text and composing it against
  the (optional) background, the background can
  be expanded to provide some padding between the
  text and any base image onto which it is later
  composed.  The default no padding.

  ### Arguments

  * `string` is any string. The string will be
    HTML-escapeed to avoid malicious code injection. If you
    are completely confident that the text is safe then
    you can pass it by calling with `Phoenix.HTML.raw/1`
    on the string first.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:font` is any font recognised on the host system.
    The default is"Helvetica".

  * `:font_size` is an integer font size in pixels. The
    dfault is `50`.

  * `:text_fill_color` is the fill color of the text.
    The default is "white". If set to `:transparent` then
    the text will be rendered transparently against
    a background. A black background will be forced if a
    `:background_color` is not provided

  * `:text_stroke_color` is the color of the outline
    of each character in the string. The default is "none".

  * `:text_stroke_width` is the integer width in
    pixels of the outline of each character in the string.
    The default is `1`.

  * `:font_weight` is the [font weight](https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight).
    The alternatives `:normal`, `:bold`, `:lighter`, `:bolder`,
    or an integer between `1` and `1_000`. The default is `:normal`
    which is equivalent to `400`.

  * `:background_color` is the background fill color behind
    the text. The default is `:none` which indicates no
    background. Note that if

  * `:background_stroke` is the colour of the outline
    of the background. The default is "none",

  * `:background_stroke_width` is the integer size in pixels
    of the background border. The default is `1`.

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  * `:padding` is the padding in pixels between the
    text and the edge of the background. THe default is `0`,

  ### Returns

  * `image` or

  * raises an exception

  ### Notes

  * There is no text wrapping, justification or kerning
    applied. This means this function is not a general
    purpose text layout function and is suitable mostly
    for overlaying text for emphasis over another image.

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec new_from_string!(String.t(), Keyword.t()) :: Vimage.t() | no_return()
  def new_from_string!(string, options \\ []) do
    case new_from_string(string, options) do
      {:ok, image} -> image
      {:error, reason} -> raise Image.Error, reason
    end
  end

  @doc """
  Creates an image from the provided text.

  This function creates an image from the text
  but does not apply a background or padding.

  ### Arguments

  * `string` is any string. The string will be
    HTML-escapeed to avoid malicious code injection. If you
    are completely confident that the text is safe then
    you can pass it by calling with `Phoenix.HTML.raw/1`
    on the string first.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:font` is any font recognised on the host system.
    The default is"Helvetica".

  * `:font_size` is an integer font size in pixels. The
    dfault is `50`.

  * `:text_fill_color` is the fill color of the text.
    The default is "white". If set to `:transparent` then
    the text will be rendered transparently against
    a background. A black background will be forced if a
    `:background_color` is not provided

  * `:text_stroke_color` is the color of the outline
    of each character in the string. The default is "none".

  * `:text_stroke_width` is the integer width in
    pixels of the outline of each character in the string.
    The default is `1`.

  * `:font_weight` is the [font weight](https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight).
    The alternatives `:normal`, `:bold`, `:lighter`, `:bolder`,
    or an integer between `1` and `1_000`. The default is `:normal`
    which is equivalent to `400`.

  ### Returns

  * `{:ok, image}` or

  * `{:error, reason}`

  ### Notes

  * There is no text wrapping, justification or kerning
    applied. This means this function is not a general
    purpose text layout function and is suitable mostly
    for overlaying text for emphasis over another image.

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec text(Vimage.t(), Keyword.t()) :: {:ok, Vimage.t()} | {:error, Image.error_message()}
  def text(string, options \\ [])

  def text(string, options) when is_list(options) do
    with {:ok, options} <- Options.Text.validate_options(options) do
      text(string, options)
    end
  end

  def text(string, %{} = options) do
    {:ok, text_layer} = render_text(string, options)

    if transparent_text?(options) do
      Image.convert_to_mask(text_layer)
    else
      {:ok, text_layer}
    end
  end

  @doc """
  Creates an image from the provided text and
  returns an image or raises an exception.

  This function creates an image from the text
  but does not apply a background or padding.

  ### Arguments

  * `string` is any string. The string will be
    HTML-escapeed to avoid malicious code injection. If you
    are completely confident that the text is safe then
    you can pass it by calling with `Phoenix.HTML.raw/1`
    on the string first.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:font` is any font recognised on the host system.
    The default is"Helvetica".

  * `:font_size` is an integer font size in pixels. The
    dfault is `50`.

  * `:text_fill_color` is the fill color of the text.
    The default is "white". If set to `:transparent` then
    the text will be rendered transparently against
    a background. A black background will be forced if a
    `:background_color` is not provided

  * `:text_stroke_color` is the color of the outline
    of each character in the string. The default is "none".

  * `:text_stroke_width` is the integer width in
    pixels of the outline of each character in the string.
    The default is `1`.

  * `:font_weight` is the [font weight](https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight).
    The alternatives `:normal`, `:bold`, `:lighter`, `:bolder`,
    or an integer between `1` and `1_000`. The default is `:normal`
    which is equivalent to `400`.

  ### Returns

  * `image` or

  * raises an exception

  ### Notes

  * There is no text wrapping, justification or kerning
    applied. This means this function is not a general
    purpose text layout function and is suitable mostly
    for overlaying text for emphasis over another image.

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec text!(Vimage.t(), Keyword.t()) :: Vimage.t() | no_return()
  def text!(string, options \\ []) do
    case text(string, options) do
      {:ok, image} -> image
      {:error, reason} -> raise Image.Error, reason
    end
  end

  @doc """
  Adds a background to an image generated from
  text.

  ### Arguments

  * `image` is any `t:Vimage.t/0` but is expected
    to ba an image generated by `Image.Text.text/2`.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:background_color` is the background fill color behind
    the text. The default is `:none` which indicates no
    background. Note that if

  * `:background_stroke` is the colour of the outline
    of the background. The default is "none",

  * `:background_stroke_width` is the integer size in pixels
    of the background border. The default is `1`.

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  ### Returns

  * `{:ok, image}` or

  * `{:error, reason}`

  ### Notes

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec add_background(Vimage.t(), Keyword.t()) :: {:ok, Vimage.t()} | {:error, Image.error_message()}
  def add_background(image, options \\ [])

  def add_background(%Vimage{} = image, options) when is_list(options) do
    with {:ok, options} <- Options.Text.validate_options(options) do
      add_background(image, options)
    end
  end

  def add_background(%Vimage{} = image, %{background_color: :none} = _options) do
    {:ok, image}
  end

  def add_background(%Vimage{} = image, %{} = options) do
    {:ok, background} = render_background(image, options)

    # If its transparent text then the image
    # is a mask and we add it as the alpha channel
    # otherwise just composite the two images

    if transparent_text?(options) do
      Operation.bandjoin([background, image])
    else
      Operation.composite2(background, image, :VIPS_BLEND_MODE_OVER)
    end
  end

  @doc """
  Adds a background to an image generated from
  text returning and image or raising an exception.

  ### Arguments

  * `image` is any `t:Vimage.t/0` but is expected
    to ba an image generated by `Image.Text.text/2`.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:background_color` is the background fill color behind
    the text. The default is `:none` which indicates no
    background. Note that if

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  ### Returns

  * `image` or

  * raises an exception

  ### Notes

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec add_background!(Vimage.t(), Keyword.t()) :: Vimage.t() | no_return()
  def add_background!(image, options \\ []) do
    case add_background(image, options) do
      {:ok, image} -> image
      {:error, reason} -> raise Image.Error, reason
    end
  end

  @doc """
  Adds padding to a background to an image generated from
  text.

  ### Arguments

  * `image` is any `t:Vimage.t/0` but is expected
    to ba an image generated by `Image.Text.add_background/2`.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:background_color` is the background fill color behind
    the text. The default is `:none` which indicates no
    background. Note that if

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  * `:padding` is the padding in pixels between the
    text and the edge of the background. THe default is `0`,

  ### Returns

  * `{:ok, image}` or

  * `{:error, reason}`

  ### Notes

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec add_background_padding(Vimage.t(), Keyword.t()) :: {:ok, Vimage.t()} | {:error, Image.error_message()}
  def add_background_padding(image, options \\ [])

  def add_background_padding(%Vimage{} = image, options) when is_list(options) do
    with {:ok, options} <- Options.Text.validate_options(options) do
      add_background_padding(image, options)
    end
  end

  def add_background_padding(%Vimage{} = image, %{background_color: :none} = _options) do
    {:ok, image}
  end

  def add_background_padding(%Vimage{} = image, %{} = options)  do
    padding =
      Map.get(options, :padding)

    options =
      options
      |> Map.put_new(:background_width, Image.width(image) + padding * 2)
      |> Map.put_new(:background_height, Image.height(image) + padding * 2)

    width = Map.get(options, :background_width)
    height = Map.get(options, :background_height)
    opacity = Map.get(options, :opacity)

    background_color =
      options
      |> Map.get(:background_color)
      |> Image.Color.rgba_color!(opacity)

    Operation.embed(image, padding, padding, width, height, background: background_color)
  end

  @doc """
  Adds padding to a background to an image generated from
  text returning an image or raising an exception.

  ### Arguments

  * `image` is any `t:Vimage.t/0` but is expected
    to ba an image generated by `Image.Text.add_background/2`.

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:background_color` is the background fill color behind
    the text. The default is `:none` which indicates no
    background. Note that if

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  * `:padding` is the padding in pixels between the
    text and the edge of the background. THe default is `0`,

  ### Returns

  * `image` or

  * raises an exception

  ### Notes

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec add_background_padding!(Vimage.t(), Keyword.t()) :: Vimage.t() | no_return()
  def add_background_padding!(image, options \\ []) do
    case add_background_padding(image, options) do
      {:ok, image} -> image
      {:error, reason} -> raise Image.Error, reason
    end
  end

  @doc """
  Adds a border on an image, typically an
  image generated from a string.

  ### Arguments

  * `image` is any `t:Vimage.t/0`

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:background_stroke` is the colour of the outline
    of the background. The default is "none",

  * `:background_stroke_width` is the integer size in pixels
    of the background border. The default is `1`.

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  ### Returns

  * `{:ok, image}` or

  * `{:error, reason}`

  ### Notes

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec add_background_border(Vimage.t(), Keyword.t()) :: {:ok, Vimage.t()} | {:error, Image.error_message()}
  def add_background_border(image, options \\ [])

  def add_background_border(%Vimage{} = image, options) when is_list(options) do
    with {:ok, options} <- Options.Text.validate_options(options) do
      add_background_border(image, options)
    end
  end

  def add_background_border(image, %{background_stroke: :none} = _options) do
    {:ok, image}
  end

  def add_background_border(image, %{padding: 0} = _options) do
    {:ok, image}
  end

  def add_background_border(image, %{} = options) do
    width = Map.get(options, :background_width, Image.width(image))
    height = Map.get(options, :background_height, Image.height(image))

    svg = """
    <svg width="#{width}px" height="#{height}px">
      <rect
        fill="none"
        stroke="#{options.background_stroke}"
        stroke-width="#{options.background_stroke_width}"
        opacity="#{options.opacity}"
        width="100%"
        height="100%"
      />
    </svg>
    """

    {:ok, {border, _flags}} = Operation.svgload_buffer(svg)
    Operation.composite2(image, border, :VIPS_BLEND_MODE_OVER)
  end

  @doc """
  Adds a border on an image, typically an
  image generated from a string. Returns an
  image or raises an exception.

  ### Arguments

  * `image` is any `t:Vimage.t/0`

  * `options` is a `t:Keyword.t/0` list of options

  ### Options

  * `:background_stroke` is the colour of the outline
    of the background. The default is "none",

  * `:background_stroke_width` is the integer size in pixels
    of the background border. The default is `1`.

  * `:opacity` is the opacity of the background. It is a
    float between `0.0` and `1.0` where `0.0` means transparent
    and `1.0` means opaque. The default is `0.7`.

  ### Returns

  * `image` or

  * raises an exception

  ### Notes

  * Colors may be any valid
    [CSS color name](https://www.w3.org/wiki/CSS/Properties/color/keywords) or
    a six hexidecimal digit string prefixed with `#`. For example
    `#FF00FF` for the color "Fuschia".

  """
  @spec add_background_border!(Vimage.t(), Keyword.t()) :: Vimage.t() | no_return()
  def add_background_border!(image, options \\ []) do
    case add_background_border(image, options) do
      {:ok, image} -> image
      {:error, reason} -> raise Image.Error, reason
    end
  end

  # For transparent text we need to render the text in
  # white which is then converted later to a transparency
  # mask

  defp render_text(text, %{text_fill_color: :transparent} = options) do
    render_text(text, Map.put(options, :text_fill_color, :white))
  end

  defp render_text(text, %{} = options) do
    height = Map.get(options, :height, round(options.font_size * 1.5))
    dy = div(height - options.font_size, 2)

    svg = """
    <svg height="#{options.font_size}px">
      <style type="text/css">
        svg text {
          font-family: #{options.font};
          font-size: #{options.font_size};
          font-weight: #{options.font_weight};
          fill: #{options.text_fill_color};
          stroke: #{options.text_stroke_color};
          stroke-width: #{options.text_stroke_width};
          text-anchor: middle;
        }
      </style>
      <text dy="#{dy}" x="50%" y="50%">#{text}</text>
    </svg>
    """

    {:ok, {image, _flags}} = Operation.svgload_buffer(svg)
    {:ok, image}
  end

  # Render a background rectangle and return
  # it without its alpha channel since we will
  # apply transparency from the text image

  # Don't apply a background stroke if there is
  # padding since we want the stroke around the
  # padded area.

  defp render_background(image, %{} = options) do
    width = Map.get(options, :background_width, Image.width(image))
    height = Map.get(options, :background_height, Image.height(image))
    background_stroke = if options.padding > 0, do: :none, else: options.background_stroke

    svg = """
    <svg width="#{width}px" height="#{height}px">
      <rect
        fill="#{options.background_color}"
        stroke="#{background_stroke}"
        stroke-width="#{options.background_stroke_width}"
        opacity="#{options.opacity}"
        width="100%"
        height="100%"
      />
    </svg>
    """

    {:ok, {rectangle, _flags}} = Operation.svgload_buffer(svg)

    if transparent_text?(options) do
      Operation.extract_band(rectangle, 0, n: 3)
    else
      {:ok, rectangle}
    end
  end

  defp transparent_text?(%{} = options) do
    Map.get(options, :text_fill_color) in [:transparent, nil]
  end

  defp escape_html_text({:safe, string}) do
    {:ok, string}
  end

  defp escape_html_text(string) do
    string =
      string
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

    {:ok, string}
  end
end