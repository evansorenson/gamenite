defmodule GameniteWeb.Components.Kodenames.Options do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, ErrorTag, Submit, Select, Checkbox, NumberInput}
  alias GameniteWeb.Components.OptionsTable.Row

  prop(game_changeset, :map, required: true)
  prop(change, :event, required: true)
  prop(submit, :event, required: true)

  def render(assigns) do
    ~F"""
    <Form for={@game_changeset} as={:game} {=@change} {=@submit} opts={autocomplete: "off"}>
    <table class="table shadow-md">
      <tbody>
    <Row name={:timer_enabled?} label={"Timer Enabled"} first?={true}>
      <:icon>
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
      </:icon>
      <:input>
    <Checkbox/>
    </:input>
    </Row>
    <Row name={:timer_length} label={"Timer Length"} last?={true}>
    <:icon>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    </:icon>
    <:input>
    <NumberInput/>
    </:input>
    </Row>

      </tbody>
    </table>
    <Field name={:teams}>
      <ErrorTag/>
    </Field>
    <Submit class="btn-blurple w-full">Start Game</Submit>
    </Form>
    """
  end
end
