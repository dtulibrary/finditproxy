PrimoProxy::Application.routes.draw do
  #get "proxy/index"
  get "/" => "proxy#index"
  match "*path" => 'proxy#render_error' # Render 404
end
