defmodule Algora.Mailer do
  @moduledoc false
  use Swoosh.Mailer, otp_app: :algora

  require Logger

  def deliver_with_logging(mail) do
    case deliver(mail) do
      {:ok, _} ->
        {:ok, mail}

      {:error, reason} ->
        Logger.error("""
        Email delivery failed:

        Subject: #{mail.subject}
        To: #{inspect(mail.to)}
        Reason: #{inspect(reason, pretty: true)}
        """)

        {:error, reason}
    end
  end

  def html_template(template_params, opts \\ []) do
    """
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <!--[if gte mso 9]><xml>
          <o:OfficeDocumentSettings>
          <o:AllowPNG/>
          <o:PixelsPerInch>96</o:PixelsPerInch>
          </o:OfficeDocumentSettings>
        </xml><![endif]-->
      </head>
      <body style="margin: 0; padding: 0; min-width: 100%; background-color: #ffffff;">
       #{preheader_section(opts[:preheader])}
        <div style="background-color: #ffffff; box-sizing: border-box; display: block; padding: 0;">
          <table cellpadding="0" cellspacing="0" width="100%">
            <tr>
              <td>
                #{html_sections(template_params)}
              </td>
            </tr>
          </table>
        </div>
      </body>
    </html>
    """
  end

  def text_template(template_params) do
    """
    ==============================

    #{text_sections(template_params)}

    ==============================
    """
  end

  defp text_sections(template_params) do
    template_params
    |> Enum.map(fn {type, value} -> text_section(type, value) end)
    |> Enum.intersperse("\n\n")
  end

  defp text_section(:cta, %{href: href, src: src}) do
    ~s|#{href}\n\n#{src}|
  end

  defp text_section(_, value) do
    value
  end

  defp html_sections(template_params) do
    for {type, value} <- template_params,
        do: html_section(type, value)
  end

  defp html_section(:markdown, value) do
    html = Algora.Markdown.render_unsafe(value)

    ~s"""
    <table cellpadding="0" cellspacing="0" width="100%">
      <tr>
        <td>
          #{html}
        </td>
      </tr>
    </table>
    """
  end

  defp html_section(type, value) do
    ~s|<p style="font-family: sans-serif; font-size: 16px; line-height: 1.5; padding-top: 0;">| <>
      html_section_by_type(type, value) <> ~s|</p>|
  end

  defp html_section_by_type(:cta, %{href: href, src: src}) do
    ~s|<a href="#{href}" style="word-break: break-all; word-wrap: break-word;">| <>
      ~s|<img src="#{src}" style="width: 100%; height: auto;">| <>
      ~s|</a>|
  end

  defp html_section_by_type(:url, value) do
    ~s|<a href="#{value}" style="word-break: break-all; word-wrap: break-word;">| <>
      value <> ~s|</a>|
  end

  defp html_section_by_type(:img, value) do
    ~s|<img src="#{value}" style="width: 100%; height: auto;">|
  end

  defp html_section_by_type(_, text) do
    text
  end

  defp preheader_section(nil), do: ""

  defp preheader_section(preheader),
    do: """
    <div class="preheader" style="display: none; max-width: 0; max-height: 0; overflow: hidden; font-size: 1px; line-height: 1px; color: #fff; opacity: 0;">
      #{preheader}
    </div>
    <div style="display: none; max-height: 0px; overflow: hidden;">
      &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy; &#847; &zwnj; &nbsp; &#8199; &shy;
    </div>
    """
end
