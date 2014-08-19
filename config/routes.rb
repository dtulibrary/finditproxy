FinditProxy::Application.routes.draw do
  get   "/:key" => "proxy#index"
  match "*path" => 'proxy#render_error' # Render 404
end
