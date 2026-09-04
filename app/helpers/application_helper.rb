module ApplicationHelper
  # Icono de Bootstrap Icons como SVG en línea, servido por la gema.
  #
  # Antes la hoja de iconos se cargaba desde cdn.jsdelivr.net, lo que rompía el
  # uso sin conexión y metía un tercero en el CSP mientras el resto del stack no
  # depende de red externa (docs/styles.md §7, §10.10). La gema `bootstrap-icons`
  # no distribuye una fuente: expone los trazos, así que el icono se inserta como
  # SVG. Hereda el color por `fill="currentColor"`, de modo que las utilidades
  # `.text-success`, `.text-danger`, etc. siguen funcionando igual.
  #
  #   = bi_icon("check-lg", class: "text-success me-2")
  #   = bi_icon("list", "aria-label": t("navigation.toggle_side_menu"))
  #
  # Sin `aria-label` la gema marca el SVG como `aria-hidden="true"`, que es lo
  # correcto cuando el icono acompaña a un texto.
  def bi_icon(symbol, **options)
    BootstrapIcons::BootstrapIcon.new(symbol, options).to_svg.html_safe
  end
end
