defmodule BernWeb.LambdaLive do
  use BernWeb, :live_view
  alias Bern.{LambdaTopic, LambdaTopicVote}

  @max_votes 3

  def mount(_params, %{"ip" => ip}, socket) do
    {:ok,
      socket
      |> assign(:ip, ip)
      |> assign(:topics, get_topics())
      |> assign(:my_votes, get_my_votes(ip))
      |> assign(:max_votes, @max_votes)
      |> assign(:proposed_topic, LambdaTopic.changeset(%{}))
      |> track_attendees()
    }
  end

  defp get_topics(), do: LambdaTopic.all()

  def render(assigns) do
    ~L"""
    <div class="flex flex-row mb-8 space-x-2">
      <div class="flex w-1/3 flex-col">
        <div class="bg-brand-100 shadow sm:rounded-lg">
          <div class="px-3 py-4 sm:p-2 ">
            <dl class="grid grid-cols-2 gap-1">
              <dt class="text-sm font-medium text-gray-500">
                Your IP
              </dt>
              <dd class="text-sm text-gray-900">
                <%= @ip %>
              </dd>

              <dt class="text-sm font-medium text-gray-500">
                Available Votes
              </dt>
              <dd class="text-sm text-gray-900">
                <%= length(@my_votes) %>/<%= @max_votes %>
              </dd>

              <dt class="text-sm font-medium text-gray-500">
                # Attendees
              </dt>
              <dd class="text-sm text-gray-900">
                <%= @attendees_count %>
              </dd>
            </dl>
          </div>
        </div>

        <div class="relative my-6">
          <div class="absolute inset-0 flex items-center" aria-hidden="true">
            <div class="w-full border-t border-gray-300"></div>
          </div>
          <div class="relative flex justify-center">
            <span class="px-2 bg-white text-sm text-gray-500">
              Suggested Topics
            </span>
          </div>
        </div>

        <div>
          <div class="grid grid-flow-row grid-cols-1 grid-rows-max gap-2">
          <%= for topic <- @topics do %>
            <div id="<%= topic.id %>" class="bg-gray-100 shadow sm:rounded-lg">
              <div class="px-4 py-5 sm:p-4">
                <div class="flex space-x-2">
                  <div class="flex-initial">
                  <%= cond do %>
                    <% topic.id not in @my_votes && @max_votes > length(@my_votes) -> %>
                      <%# Eligible vote %>
                      <button id="<%= topic.id %>-upvote" phx-click="upvote" phx-value-id="<%= topic.id %>">
                        <svg class="w-6 h-6 hover:text-green-500 transition-colors duration-150" fill="none" stroke="currentColor"
                          viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M9 11l3-3m0 0l3 3m-3-3v8m0-13a9 9 0 110 18 9 9 0 010-18z">
                          </path>
                        </svg>
                        <span class="sr-only">Upvote</span>
                      </button>
                    <% topic.id in @my_votes -> %>
                      <%# Already voted %>
                      <button id="<%= topic.id %>-downvote" phx-click="downvote" phx-value-id="<%= topic.id %>">
                        <svg class="w-6 h-6 text-green-500 transform hover:rotate-180 hover:text-red-500 transition ease-out duration-300" fill="none" stroke="currentColor"
                          viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="M9 11l3-3m0 0l3 3m-3-3v8m0-13a9 9 0 110 18 9 9 0 010-18z">
                          </path>
                        </svg>
                        <span class="sr-only">Remove upvote</span>
                      </button>
                    <% length(@my_votes) >= @max_votes -> %>
                      <%# Exceeding votes %>
                      <svg class="w-6 h-6 text-gray-300 cursor-not-allowed" fill="none" stroke="currentColor"
                        viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                          d="M9 11l3-3m0 0l3 3m-3-3v8m0-13a9 9 0 110 18 9 9 0 010-18z">
                        </path>
                      </svg>
                    <% topic.covered -> %>
                      <% nil %>
                  <% end %>
                  <div class="text-xs text-center">
                    <%= topic.votes_count %>
                  </div>
                </div>
                <div class="flex overflow-x-auto">
                  <div class="w-full">
                    <%= if topic.covered do %>
                      <strike><%= topic.topic %></strike> (covered)
                    <% else %>
                      <%= topic.topic %>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <% end %>

          <%= f = form_for @proposed_topic, "#", [class: "transition-transform duration-300 bg-gray-100 shadow sm:rounded-lg", phx_change: :validate, phx_submit: :submit_topic] %>
            <div class="px-2 py-3">
              <div>
                <%= text_input f, :topic,
                  placeholder: "Propose a topic...",
                  autocomplete: "off",
                  class: "p-2 shadow-sm focus:ring-brand-500 focus:border-brand-500 block w-full sm:text-sm border-gray-300 rounded-md" %>
                <%= error_tag f, :topic %>
              </div>

              <%= submit "Submit Topic", class: "mt-2 relative inline-flex items-center px-4 py-1 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-brand-600 hover:bg-brand-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-brand-500 disabled:cursor-not-allowed disabled:opacity-50 transition ease-in-out duration-150" %>
            </div>
          </form>
          </div>
        </div>
      </div>

      <div class="w-2/3">
        Sup
      </div>
    </div>
    """
  end

  def handle_event("validate", %{"lambda_topic" => %{"topic" => topic}}, socket) do
    {:noreply, assign(socket, :proposed_topic, LambdaTopic.changeset(%{topic: topic}))}
  end

  @thankyou """
  Thank you for proposing a topic! It's in the moderation queue now and will appear when approved.
  """ |> String.trim()
  def handle_event("submit_topic", %{"lambda_topic" => %{"topic" => topic}}, socket) do
    {:noreply, case LambdaTopic.create(topic) do
      :ok ->
        socket
        |> assign(:proposed_topic, LambdaTopic.changeset(%{}))
        |> put_flash(:info, @thankyou)
      {:error, changeset} ->
        assign(socket, :proposed_topic, changeset)
    end}
  end

  def handle_event("upvote", %{"id" => topic_id}, socket) do
    if length(socket.assigns.my_votes) < @max_votes do
      LambdaTopicVote.create(topic_id, socket.assigns.ip)
    end

    {:noreply, assign(socket, my_votes: get_my_votes(socket.assigns.ip))}
  end

  def handle_event("downvote", %{"id" => topic_id}, socket) do
    LambdaTopicVote.delete(topic_id, socket.assigns.ip)
    {:noreply, assign(socket, my_votes: get_my_votes(socket.assigns.ip))}
  end

  def handle_info([:topic, :new, _], socket), do: {:noreply, socket}
  def handle_info([:topic | _], socket) do
    {:noreply, assign(socket, topics: get_topics(), my_votes: get_my_votes(socket.assigns.ip))}
  end

  def handle_info(
      %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
      %{assigns: %{attendees_count: count}} = socket
    ) do
    attendees = count + map_size(joins) - map_size(leaves)
    {:noreply, assign(socket, :attendees_count, attendees)}
  end

  defp get_my_votes(ip), do: LambdaTopicVote.for(ip: ip) |> Enum.map(& &1.topic_id)

  defp track_attendees(socket) do
    topic = "lambda"
    attendees_count = topic |> BernWeb.Presence.list() |> map_size()
    if connected?(socket) do
      BernWeb.Endpoint.subscribe(topic)
      BernWeb.Presence.track(self(), topic, socket.assigns.ip, %{
        online_at: inspect(System.system_time(:second))
      })
    end

    assign(socket, :attendees_count, attendees_count)
  end
end
