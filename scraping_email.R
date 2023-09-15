# let's extract the email of several universities of medicine from
# https://emec.mec.gov.br/

library(RSelenium)
library(wdman)
library(netstat)
library(tidyverse)
library(rvest)

wpage <- "https://emec.mec.gov.br"
maxpages <- 13
# selenium()

selenium_object <- selenium(retcommand = TRUE, check = FALSE)
remote_driver <- rsDriver(
  browser = "firefox",
  port = free_port()
)

remDr <- remote_driver$client

remDr$navigate(wpage)
Sys.sleep(15)

barra <- remDr$findElement(using = "id", "mainFrame")
hh <- barra$getElementAttribute(attrName = "src")[[1]]
remDr$navigate(hh)
Sys.sleep(15)

# finding elements
radio_buttom <- remDr$findElements(using = "id", value = "consulta_avancada_rad_buscar_por")
radio_buttom[[2]]$clickElement()

pesq_exata <- remDr$findElement(using = "id", value = "consulta_avancada_chk_pesquisa_exata")
pesq_exata$clickElement()

curso <- remDr$findElement(using = "id", value = "txt_no_curso")
curso$sendKeysToElement(sendKeys = list('medicina'))

situacao <- remDr$findElement(using = "xpath", value = "/html/body/div[2]/div[2]/div/div[3]/div[1]/div/form/table/tbody/tr[21]/td[2]/select/option[2]")
situacao$clickElement()


remDr$findElement(using = "id", value = "btnPesqAvancada")$clickElement()
Sys.sleep(15)


# find  table in html
tab <- remDr$findElement(using = "xpath", value = "/html/body/div[2]/div[2]/div/div[3]/div[1]/div/div/table/tbody")
img <- tab$findChildElements(using = "tag", "img")

pop <- lapply(img, function(x) x$getElementAttribute("onclick"))

pop <- Reduce(c, pop) %>% Reduce(c, .)
pop <- str_extract(pop, "(?<=popup\\(\\').*(?=\\',)")

for(i in 2:maxpages){
  remDr$findElement(using = "xpath", value = "/html/body/div[2]/div[2]/div/div[3]/div[1]/div/div/table/tfoot/tr/td/div/div/ul/li[17]")$clickElement()
  Sys.sleep(20)
  # find  table in html
  tab <- remDr$findElement(using = "xpath", value = "/html/body/div[2]/div[2]/div/div[3]/div[1]/div/div/table/tbody")
  img <- tab$findChildElements(using = "tag", "img")
  
  pop_aux <- lapply(img, function(x) x$getElementAttribute("onclick"))
  
  pop_aux <- Reduce(c, pop_aux) %>% Reduce(c, .)
  pop_aux <- str_extract(pop_aux, "(?<=popup\\(\\').*(?=\\',)")
  pop <- c(pop, pop_aux)
  
}

extract <- function(xx){
  
  pagina <- httr::GET(paste0(wpage, xx))
  httr::http_type(pagina)
  jsonText <- httr::content(pagina, "text")
  jsonText <- str_split_1(jsonText, "\\n")
  
  src_p <- grep("src=", jsonText)
  int_p <- grep("consulta_cadastro", jsonText)
  
  l_int <- src_p[src_p > int_p][1]
  end <- str_extract(jsonText[l_int], "(?<=\\\").*(?=\\\")")
  
  
  pagina2 <- httr::GET(paste0(wpage, end))
  httr::http_type(pagina2)
  jsonText <- httr::content(x = pagina2, as = "text", encoding = "latin1")
  jsonText <- str_split_1(jsonText, "\\n")
  
  linha <- grepl("detalhe_ies", jsonText)
  end2 <- str_extract(jsonText[linha], "(?<=link=\\\").*(?=\\\")")
  
  
  pagina3 <- httr::GET(paste0(wpage, end2))
  jsonText <- httr::content(x = pagina3, as = "text", encoding = "latin1")
  jsonText <- str_split_1(jsonText, "\\n")
  
  page <- read_html(paste0(wpage, end2))
  
  
  
  texto <- page %>%
    rvest::html_nodes("td") %>%
    html_children() %>% html_text() %>% 
    gsub("\\n", "", .) %>% 
    trimws("both")
  
  ll <- grep("[Ee]-mail", texto)
  
  t_int <- texto[ll] %>% str_split_1("  ")
  
  t_int <- t_int[t_int != ""]
  
  email <- t_int[grep("[Ee]-mail", t_int)+1]
  nome <- t_int[grep("Nome .* IES", t_int)+1]
  tel <- t_int[grep("Telefone", t_int)+1]
  UF <- t_int[grep("UF:", t_int)+1]
  cidade <- t_int[grep("Munic[íi]pio", t_int)+1]
  Site <- t_int[grep("S[íi]tio", t_int)+1]
  ms_site <- paste0(wpage, xx)
  
  data.frame(nome, email, tel, UF, cidade, Site, ms_site)
  
}

xx = pop[365]

dados <- lapply(pop, extract)
length(dados)


df <- Reduce(rbind, dados)

df <- df %>% 
  mutate(
    nr = row_number()
  )
openxlsx::write.xlsx(df, "output/raw_data.xlsx")


df %>% 
  distinct(nome, email, cidade, UF, .keep_all = TRUE) %>% 
  openxlsx::write.xlsx("output/filtered_data.xlsx")
  

#close the server
remote_driver$server$stop()
