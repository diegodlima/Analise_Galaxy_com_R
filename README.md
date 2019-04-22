# Análise de Polaridade dos Dispositivos Galaxy S10 e Galaxy Fold, para planejamento estratégico
Este projeto tem como objetivo demonstrar a utilização da análise de sentimentos quando empregada para planejamento estratégico.<br />
A análise será realizada para compreender as polaridades referentes a dois aparelhos da Samsung: Galaxy S10 e Galaxy Fold.<br />
A escolha destes aparelhos tem por objetivo contextualizar a necessidade de compreender as expectativas do público referente ao seu futuro lançamento (Galaxy Fold), tendo como parâmetro de comparação o seu mais recente produto já lançado recentemente (Galaxy S10).<br />
Inicialmente gostaria de esclarecer que a marca e modelos foram aleatoriamente escolhidos, sem intenção de expressar quaisquer opiniões a respeito.<br />
Dito isto, é importante que o leitor se conscientize de que os dados coletados são apenas uma pequena amostra do conjunto exponencialmente maior de informações existentes a respeito dos produtos. Portanto, toda a análise realizada neste projeto deve ser endereçada somente para este conjunto de dados, e para o momento da coleta de dados, não generalizando assim o real posicionamento estratégico da empresa quanto aos produtos analisados em quaisquer outros momentos ou fontes.<br />
<br />
O relatório final com as análises pode ser verificado em: https://diegodlima.github.io/Analise_Galaxy_com_R/
<hr />

<h3>Descrição de arquivos</h3>
- <b>tweets.bd:</b> banco de dados SQLite com os datasets contendo os tweets coletados<br />
- <b>*.tar:</b> bibliotecas para análise de polaridade utilizando Naive Bayes<br />
- <b>*.txt</b> banco de palavras positivas e negativas<br />
- <b>utils.R</b> arquivo com funções para limpeza de tweets<br />
- <b>index.html:</b> arquivo contendo o relatório final
<hr />
<h3>Escopo do Projeto</h3>
<b>Objetivo: </b>analisar as expectativas de clientes referente ao Galaxy S10 e Galaxy Fold, para sugerir tomadas de ações que resultem na melhora do posicionamento estratégico do Galaxy Fold, abordando possíveis expectativas negativas a respeito do produto.<br />
<b>Justificativa: </b>sendo o Galaxy S10 um produto já lançado de um modelo em sua maturidade, este servirá incialmente como referência para definir as metas a se atingir para o Galaxy Fold.<br />
<b>Fonte de dados: </b>Twitters em inglês.<br />
<b>Tamanho do conjunto de dados: </b>1000 tweets para cada produto.<br />
<b>Data de coleta dados: </b>16/04/19 aproximadamente às 16 horas.<br />
