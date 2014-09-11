FinditProxy::Application.routes.draw do
  get   ":version/:key/:service" => "proxy#index"
  match "*path" => 'proxy#render_error' # Render 404
end
