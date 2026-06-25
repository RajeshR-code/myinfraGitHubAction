resource "azurerm_resource_group" "myrg" {
    for_each = var.myinfradetails

    name = each.value.rg_name
    location = each.value.rg_location
}

resource "azurerm_virtual_network" "myvnet" {
  depends_on = [ azurerm_resource_group.myrg ]

  for_each            = var.myinfradetails
  name                = each.value.vnet_name
  location            = each.value.rg_location
  resource_group_name = each.value.rg_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "mysubnet"{
  
  depends_on = [ azurerm_resource_group.myrg,azurerm_virtual_network.myvnet ]

  for_each             = var.myinfradetails
  name                 = each.value.subnet_name
  resource_group_name  = each.value.rg_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "mypublicip" {
  
  depends_on = [ azurerm_resource_group.myrg ]

    for_each          = var.myinfradetails
  name                = each.value.publicIpName
  resource_group_name = each.value.rg_name
  location            = each.value.rg_location
  allocation_method   = each.value.allocation_method
}

resource "azurerm_network_interface" "mynic" {
  
  depends_on = [ azurerm_resource_group.myrg,azurerm_virtual_network.myvnet,azurerm_subnet.mysubnet ]
  for_each            = var.myinfradetails
  name                = each.value.nic_name
  location            = each.value.rg_location
  resource_group_name = each.value.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mysubnet[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypublicip[each.key].id
  }
}

resource "azurerm_windows_virtual_machine" "rr-winvm" {

  depends_on = [ azurerm_resource_group.myrg,azurerm_virtual_network.myvnet,azurerm_subnet.mysubnet,azurerm_network_interface.mynic ]
  
  for_each            = var.myinfradetails
  name                = each.value.vm_name
  resource_group_name = each.value.rg_name
  location            = each.value.rg_location
  size                = each.value.vm_size
  admin_username      = each.value.admin_username
  admin_password      = each.value.admin_password
  network_interface_ids = [
    azurerm_network_interface.mynic[each.key].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

