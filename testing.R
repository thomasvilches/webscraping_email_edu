
# open a browser
remDr$open()

# maximize window
remDr$maxWindowSize()

# navigate to website
remDr$navigate('https://www.ebay.com')

# finding elements
electronics_object <- remDr$findElement(using = 'link text', 'Esportes')
electronics_object$clickElement()

# go back
remDr$goBack()

# search for an item
search_box <- remDr$findElement(using = 'id', 'gh-ac')
search_box$sendKeysToElement(list('Playstation 5', key = 'enter'))

# html body div#geral div#colunas div#conteudo_esquerda div#tabs.ui-tabs.ui-widget.ui-widget-content.ui-corner-all div#avancada.ui-tabs-panel.ui-widget-content.ui-corner-bottom div div#div_listar_consulta_avancada table#tbDataGridNova tbody#tbyDados tr.linha_tr_body_nova_grid td img