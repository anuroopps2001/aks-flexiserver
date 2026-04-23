output "outbound_ips" {
  value = azurerm_linux_web_app.frontend_app.possible_outbound_ip_address_list
}