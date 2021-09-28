defmodule GameniteWeb.InputHelpers do
  use Phoenix.HTML

  def array_input(form, field, attr \\ []) do
    values = Phoenix.HTML.Form.input_value(form, field) || []
    id = Phoenix.HTML.Form.input_id(form,field)
    content_tag :ul, id: container_id(id), data: [index: Enum.count(values) ] do
      values
      |> Enum.with_index()
      |> Enum.map(fn {val, idx} ->
        form_elements(form, field, val, idx, attr)
      end)
    end
  end

  def array_add_button(form, field, options \\ nil) do
    id = Phoenix.HTML.Form.input_id(form,field)
    # {:safe, content}
    content = form_elements(form,field,"","__name__", options)
      |> safe_to_string
      # |> html_escape
    data = [
      prototype: content,
      container: container_id(id)
    ];
    link("Add", to: "#",data: data, class: "add-form-field")
  end

  defp form_elements(form, field, val, idx, [options: options] = _attr) do
    id = Phoenix.HTML.Form.input_id(form,field)
    new_id = id <> "_#{idx}"
    input_opts = [
      name: new_field_name(form,field),
      value: val,
      id: new_id
    ]

    case idx do
      0 ->
        content_tag :li do
          [
            apply(Phoenix.HTML.Form, :select, [form, field, options, input_opts])
          ]
        end
      _ ->
        content_tag :li do
          [
            apply(Phoenix.HTML.Form, :select, [form, field, options, input_opts]),
            link("Remove", to: "#", data: [id: new_id], class: "remove-form-field")
          ]
        end
    end

  end

  defp form_elements(form, field, k ,v, _attr) do
    type = Phoenix.HTML.Form.input_type(form, field)
    id = Phoenix.HTML.Form.input_id(form,field)
    new_id = id <> "_#{v}"
    input_opts = [
      name: new_field_name(form,field),
      value: k,
      id: new_id
    ]
    content_tag :li do
      [
        apply(Phoenix.HTML.Form, type, [form, field, input_opts ]),
        link("Remove", to: "#", data: [id: new_id], class: "remove-form-field")
      ]
    end
  end

  defp container_id(id), do: id <> "_container"

  defp new_field_name(form, field) do
    Phoenix.HTML.Form.input_name(form, field) <> "[]"
  end
end
