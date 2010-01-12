worker_processes 2

Rainbows! do
  use :ThreadSpawn
  worker_connections 10
end
