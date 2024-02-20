resource "azurerm_resource_group" "lab" {
  name     = "${var.project_prefix}-${var.resource_group_name}"
  location = var.location
}

resource "azurerm_virtual_network" "lab" {
  name                = "${var.project_prefix}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_subnet" "db" {
  name                 = "${var.project_prefix}-db-sn"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "lab" {
  name                = "${var.project_prefix}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.lab.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "lab" {
  name                  = "${var.project_prefix}-VnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.lab.name
  virtual_network_id    = azurerm_virtual_network.lab.id
  resource_group_name   = azurerm_resource_group.lab.name
  depends_on            = [azurerm_subnet.db]
}

resource "random_password" "admin_password" {
  special = "false"
  length  = 32
}

resource "azurerm_postgresql_flexible_server" "lab" {
  name                = "${var.project_prefix}-psql-flex-server"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  version             = var.POSTGRES_VERSION
  delegated_subnet_id = azurerm_subnet.db.id
  private_dns_zone_id = azurerm_private_dns_zone.lab.id
  administrator_login = var.POSTGRES_USER
  # administrator_password = var.POSTGRES_PASSWORD
  administrator_password = random_password.admin_password.result
  zone                   = "2"

  storage_mb = 32768

  sku_name   = "GP_Standard_D2ds_v5"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.lab]
}

resource "azurerm_postgresql_flexible_server_database" "lab" {
  name      = var.POSTGRES_DB
  server_id = azurerm_postgresql_flexible_server.lab.id
  collation = "en_US.utf8"
  charset   = "utf8"

  # TODO: prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = false
  }
}

resource "random_pet" "container_name" {
  prefix = var.project_prefix
}

resource "azurerm_subnet" "containers" {
  name                 = "${var.project_prefix}-containers-sn"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.0.3.0/24"]
  delegation {
    name = "aciDelegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_container_group" "lab" {
  name                = "${var.project_prefix}-aci-group01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  restart_policy      = "Always"
  subnet_ids          = [azurerm_subnet.containers.id]

  container {
    name   = "${var.project_prefix}-${random_pet.container_name.id}"
    image  = var.docker_image
    cpu    = 1
    memory = 2

    secure_environment_variables = {
      SQLALCHEMY_DATABASE_URL = "postgresql://${azurerm_postgresql_flexible_server.lab.administrator_login}:${azurerm_postgresql_flexible_server.lab.administrator_password}@${azurerm_postgresql_flexible_server.lab.fqdn}/${var.POSTGRES_DB}"
    }

    ports {
      port     = var.port
      protocol = "TCP"
    }
  }
}

resource "azurerm_public_ip" "lab" {
  name                = "${var.project_prefix}-pip"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lab" {
  name                = "${var.project_prefix}-lb"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.lab.id
  }
}

resource "azurerm_lb_backend_address_pool" "lab" {
  loadbalancer_id = azurerm_lb.lab.id
  name            = "${var.project_prefix}-backend"
}

resource "azurerm_lb_rule" "lab" {
  loadbalancer_id                = azurerm_lb.lab.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8000
  frontend_ip_configuration_name = "publicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lab.id]
}

# Loadbalancer Backend Pool Association
resource "azurerm_lb_backend_address_pool_address" "container-1" {
  name                    = "${var.project_prefix}-container-1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lab.id
  virtual_network_id      = azurerm_virtual_network.lab.id
  ip_address              = azurerm_container_group.lab.ip_address
}


