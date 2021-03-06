# Carregando pacotes
library(twitteR)
library(RSQLite)
library(stringr)
library(plyr)
library(ggplot2)
library(tm)
library(RColorBrewer)
library(wordcloud)
library(dplyr)
library(tidyr)
library(slam)
library(sentiment)
library(gridExtra)
source("utils.R")

# Declarando chaves de autenticação no Twitter
# api_key <- ""
# api_secret_key <- ""
# access_token <- ""
# access_token_secret <- ""

# Autenticando
# setup_twitter_oauth(api_key, api_secret_key, access_token, access_token_secret)

# Coletando tweets
# num_tweets <- 1000
# language <- "en"
# tweets_sten <- searchTwitter("galaxy s10", num_tweets, language) %>%
#  sapply(function(x) x$getText())
# tweets_fold <- searchTwitter("galaxy fold", num_tweets, language) %>%
#  sapply(function(x) x$getText())

# Salvando tweets em Banco de Dados SQLite
# con <- dbConnect(SQLite(), "tweets.db")
# dbWriteTable(con, "sten", data.frame(tweets_sten))
# dbWriteTable(con, "fold", data.frame(tweets_fold))
# dbDisconnect(con)

# Para garantir que os resultados sejam reproduzidos, os tweets foram salvos em banco de dados
# SQLite para serem carregados e trabalhados posteriormente.

# Carrega tweets do Banco de Dados SQLite
con <- dbConnect(SQLite(), "tweets.db")
tweets_sten <- dbReadTable(con, "sten")
tweets_sten <- tweets_sten$tweets_sten
tweets_fold <- dbReadTable(con, "fold")
tweets_fold <- tweets_fold$tweets_fold
dbDisconnect(con)

# Definição do objetivo
# Para definir o objetivo, será realizada a avaliação da polaridade do Galaxy S10. Em seguida será
# realizada a avaliação do Galaxy Fold e comparadas as diferenças de desempenho de ambos.
# Posteriormente será sugerido o objetivo a ser conquistado com as sugestões que serão aparesentadas.

# Limpando tweets e removendo valores Missing
# Galaxy S10
tweets_sten_analysis <- limpaTweets(tweets_sten)
tweets_sten_analysis <- tweets_sten_analysis[!is.na(tweets_sten_analysis)]
names(tweets_sten_analysis) <- NULL

# Avaliação de polaridade do Galaxy S10
class_polar_sten <- classify_polarity(tweets_sten_analysis, algorithm = "bayes")
polaridade_sten <- class_polar_sten[, 4]

# Data set com polaridades
resultados_sten <- data.frame(
  texto = tweets_sten_analysis,
  polaridade = polaridade_sten,
  stringsAsFactors = FALSE
)

# Apresentação dos resultados de polaridade do Galaxy S10
plot_pol_sten <- ggplot(resultados_sten, aes(x = polaridade)) +
  geom_bar(aes(y = ..count.., fill = polaridade)) +
  scale_fill_brewer(palette = "RdGy") +
  scale_fill_discrete(name = "Polaridades") +
  labs(x = "Categorias", y = "Número de Tweets") +
  ggtitle("Polaridades atribuídas aos tweets sobre Galaxy S10") +
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face="bold"))

plot_pol_sten

# Na análise de polaridade, foi possível verificar que os tweets referentes ao Galaxy S10
# apresentaram maior positividade.
data.frame(table(resultados_sten$polaridade)) %>%
  mutate(
    Config = round((Freq / sum(Freq))*100, 2)
  )
# A configuração da polaridade do Galaxy S10 é:
# NEGATIVIDADE: 9,21%
# NEUTRALIDADE: 12,80%
# POSITIVIDADE: 77,99%
# Portanto, esta configuração está sendo assumida como parâmetro para uma boa polaridade do Galaxy Fold.

# Galaxy Fold
tweets_fold_analysis <- limpaTweets(tweets_fold)
tweets_fold_analysis <- tweets_fold_analysis[!is.na(tweets_fold_analysis)]
names(tweets_fold_analysis) <- NULL

# Avaliação de polaridade do Galaxy Fold
class_polar_fold <- classify_polarity(tweets_fold_analysis, algorithm = "bayes")
polaridade_fold <- class_polar_fold[, 4]

# Data set com polaridades
resultados_fold <- data.frame(
  texto = tweets_fold_analysis,
  polaridade = polaridade_fold,
  stringsAsFactors = FALSE
)

# Apresentação dos resultados de polaridade do Galaxy Fold
plot_pol_fold <- ggplot(resultados_fold, aes(x = polaridade)) +
  geom_bar(aes(y = ..count.., fill = polaridade)) + 
  scale_fill_brewer(palette = "RdGy") +
  scale_fill_discrete(name = "Polaridades") +
  labs(x = "Categorias", y = "Número de Tweets") +
  ggtitle("Polaridades atribuídas aos tweets sobre Galaxy Fold") +
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face="bold"))

plot_pol_fold

# Embora a polaridade resultante do Galaxy Fold possua uma predominância positiva, a sua
# configuração se difere negativamente em relação ao Galaxy S10.
data.frame(table(resultados_fold$polaridade)) %>%
  mutate(
    Config = round((Freq / sum(Freq))*100, 2)
  )
# A configuração da polaridade do Galaxy Fold é:
# NEGATIVIDADE: 23,12%
# NEUTRALIDADE: 15,16%
# POSITIVIDADE: 61,72%
# Portanto, foi identificado um oportunidade de melhoria reduzindo a negatividade do Galaxy Fold
# de forma que todas ações sugeridas devam possuir um potencial de melhoria que se aproxime 
# a polaridade do Galaxy Fold ao do Galaxy S10.

# Análise de Score
# Como ponto de partida para identificar possíveis pontos estratégicos a serem abordados para
# de forma à sugerir ações de melhoria, serão avaliadas as palavras utilizadas nos tweets, e
# classificadas entre boas ou ruins. Ao final será calculado o score de cada produto.

# Um conjunto de palavras positivas e negativas serão utilizados para avaliar o score de cada produto
# em relação ao uso de palavras nos tweets.
pos = readLines("palavras_positivas.txt")
neg = readLines("palavras_negativas.txt")

# Criando função para calcular scores
# Os scores serão calculados com base nas palavras utilizadas nos tweets onde, para cada palavra
# negativa será atribuído 1 ponto para negatividade, e para cada palavra positiva será atribuído
# 1 ponto para positividade.
# O cálculo final do score será dado pelo total de pontos positivos subtraído dos pontos negativos.
# Sendo assim scores com resultado 0 representa um equilibrio o que sugere neutralidade no uso das
# palavras.
calcula_score = function(tweets, pos.words, neg.words){
  # Criando um array de scores
  scores = laply(tweets,
                 function(tweet, pos.words, neg.words)
                 {
                   # Removendo pontuações, caracteres especiais e dígitos
                   tweet = gsub("[[:punct:]]", "", tweet)
                   tweet = gsub("[[:cntrl:]]", "", tweet)
                   tweet = gsub('\\d+', '', tweet)
                   # Formatando os textos para lowercase
                   tweet = sapply(tweet, tolower)
                   # Criando lista de palavras separando por espaço
                   word.list = str_split(tweet, "\\s+")
                   words = unlist(word.list)
                   
                   # Verificando se as palavras estão na lista positiva e negativa
                   pos.matches = match(words, pos.words)
                   neg.matches = match(words, neg.words)
                   # Removendo valores missing
                   pos.matches = !is.na(pos.matches)
                   neg.matches = !is.na(neg.matches)
                   # Calculando e retornando o score do texto
                   # Sempre que houver mais ocorrências negativas, o score será negativo
                   # Sempre que houver mais ocorrências positivas, o score será positivo
                   # Caso o score for 0, o texto não contém palavras positivas ou negativas
                   # contidas nas listas
                   score = sum(pos.matches) - sum(neg.matches)
                   return(score)
                 }, pos.words, neg.words)
  # Criando data frame contendo o texto e seu score
  scores.df = data.frame(text = tweets, score = scores)
  return(scores.df)
}

# Vetor contendo o número de tweets coletados de cada dispositivo
num_tweets = c(length(tweets_sten), length(tweets_fold))
# Vetor contendo todos os tweets de cada dispositivo
tweets = c(tweets_sten, tweets_fold)

# Calculando score de sentimento
scores = calcula_score(tweets, pos, neg)
# Atribui o dispositivo para os scores
scores$text = factor(rep(c("Galaxy S10", "Galaxy Fold"), num_tweets))
# Inclui campos positivo enegativo para contagem de quantas ocorrências há de cada dispositivo
scores$positivo = as.numeric(scores$score >= 1)
scores$negativo = as.numeric(scores$score <= -1)
# Calcula o score final de cada dispositivo
scores_finais <- data.frame(Dispositivo = c("Galaxy S10", "Galaxy Fold"),
                            Score = c(
                              sum(scores[scores$text == "Galaxy S10", "positivo"]) - sum(scores[scores$text == "Galaxy S10", "negativo"]),
                              sum(scores[scores$text == "Galaxy Fold", "positivo"]) - sum(scores[scores$text == "Galaxy Fold", "negativo"])
                            ))

# Plotando gráfico contendo score final de cada dispositivo
ggplot(scores_finais, aes(x = Dispositivo, y = Score)) +
  geom_col(aes(fill = Score), alpha = 0.7) +
  ggtitle("Análise de Scores dos Dispositivos") +
  geom_text(aes(label = Score), size = 3) +
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face="bold"))

# Conforme pode ser analisado no gráfico, o Galaxy S10 teve um score positivo. Porém  o Galaxy Fold
# possuiu um score inferior.
# Considerando o tamanho da amostra de 1000 tweets um score de -15 pode ser interpretado como equilibrado
# ao invés de se assumir como negativo.
# Verificando a distribuição de scores por tweet
scores_fold <- data.frame(table(scores[scores$text == "Galaxy Fold", "score"]))
ggplot(scores_fold, aes(x = Var1, y = Freq)) +
  geom_col(fill = 'lightblue', color = "darkblue", alpha = 0.7) +
  ggtitle("Distribuição de Scores para o Galaxy Fold") +
  xlab("Score") +
  ylab("Frequência") +
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face = "bold"))
# Conforme gráfico acima, a distribuição mostra que de fato houve uma predominância de neutralidade,
# ao invés da negatividade.
# Porém, neutro ou negativo, são potenciais situações para serem convertidas à positividade, resultando
# assim em melhoria.
# É importante esclarecer também que, o score negativo não representa uma expectativa negativa do
# público, como já foi evidenciado com a polaridade.
# Neste projeto o score sugere que houve um maior número de palavras negativas referente ao produto
# do que positivas, e compreender estas palavras é extremamente importante para identificar pontos
# específicos a serem melhorados.

# Para se certificar novamente de que o score negativo não está representando expectativa negativa
# ao produto, foram realizadas rápidas pesquisas na web,  e foi possível notar destaques positivos
# em relação ao Galaxy Fold, no que diz respeito à critica especializada. Isto considerando o dia 16/04/19
# aproximadamente às 16 horas.
# https://www.tecmundo.com.br/dispositivos-moveis/140452-galaxy-fold-nao-decepciona-vem-gerando-primeiras-impressoes-positivas.htm
# https://9to5google.com/2019/04/16/samsung-galaxy-fold-impressions-roundup/
# https://www.extremetech.com/mobile/289550-first-impressions-of-the-galaxy-fold-are-cautiously-optimistic
# https://www.technobuffalo.com/samsung-galaxy-fold-review

# Esta diferença existente entre o positivismo da critica especializada e o score negativo, pode se
# dar por diferentes fatores, como por exemplo:
# - Poucos tiveram acesso ao dispositivo para análise e primeiras impressões;
# - Dos poucos que tiveram acesso, muitos fazem parte da critica especializada e muitos outros são
# influenciadores e supostamente patrocinados, podendo resultar em parcialidade;
# - Consumidores em geral podem estar sendo negativos em relação a alguma característica específica
# do dispositivo.

# Este último será explorado na tentavida de identificar quais características podem estar sob suspeita
# do público.

# Para compreender melhor estes tweets, vamos analisar as palavras mais utilizadas.
# Limpeza dos tweets
# Remoção de símbolos, números e palavras positivas para se dar foco no conteúdo
# negativo presente nas mensagens
tweet_fold_clean <- limpaTweets(tweets_fold)
tweet_fold_clean <- Corpus(VectorSource(tweet_fold_clean))
tweet_fold_clean <- tm_map(tweet_fold_clean, removePunctuation)
tweet_fold_clean <- tm_map(tweet_fold_clean, content_transformer(tolower))
tweet_fold_clean <- tm_map(tweet_fold_clean, function(x) removeWords(x, stopwords()))
tweet_fold_clean <- tm_map(tweet_fold_clean, function(x) removeWords(x, pos))

# Agrupamento do conjunto de palavras em Matrix
tweet_matrix <- TermDocumentMatrix(tweet_fold_clean)

# Data set contendo a frequência de cada palavra
freq <- data.frame(rowSums(as.matrix(tweet_matrix)))
freq <- data.frame(rownames(freq), freq)
rownames(freq) <- NULL
colnames(freq) <- c("WORD", "FREQ")

# Verificando as palavras negativas de maior número de ocorrência
wordcloud(words = freq[freq$WORD %in% neg & freq$FREQ > 1, "WORD"],
          freq = freq[freq$WORD %in% neg & freq$FREQ > 1, "FREQ"],
          max.words = 100,
          scale = c(4, 1),
          random.color = TRUE,
          random.order = FALSE,
          colors = brewer.pal(8, "Dark2"))

# Com um grande destaque para a palavra "dope", vamos verificar a diferença de frequência entre
# as demais palavras, para planejar uma análise contextual do uso destas palavras
ggplot(freq[freq$WORD %in% neg & freq$FREQ > 1,], aes(x = reorder(WORD, FREQ), y = FREQ)) +
  geom_col(fill = "lightblue", color = "darkblue", alpha=0.7) +
  coord_flip() +
  xlab("PALAVRAS") +
  ylab("FREQUÊNCIA") +
  ggtitle("Frequência de palavras negativas") +
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face = "bold"))

# Com uma presença muito superior das demais, a palavra "dope" deve ser estrategicamente analisada 
# em contexto, identificando possíveis receios ou críticas a serem cobertas pela SAMSUNG
grep("dope", tweets_fold, value = TRUE)

# Análise
# Em grande maioria o texto negativa um possível uso da S-PEN no dispositivo. Em uma breve consulta nas
# discussões do tweeter procurando pela mesma expressão, pode-se verificar que de fato há uma grande
# expectativa negativa quanto ao uso da S-Pen sobre a tela dobrável, de forma que esta venha a
# possivelmente a apresentar riscos devido o material de plástico.
# Embora não confirmada para este aparelho, a S-Pen é um anseio aparente dos usuários, uma vez que
# possibilitaria explorar melhor o uso da tela maior.

# Neste ponto sugere-se que cobrindo este assunto em futuras apresentações, deixando claro se haverá
# uma S-Pen exclusiva para o aparelho. Caso houver, seria importante a demonstração e divulgação de
# testes, podendo assim obter um resultando mais positivo eliminando esta negativa
# O potencial resultado com esta ação será calculado removendo os tweets que contenham esta palavra.

# Calculando Score sem tweets com a palavra "dope"
# Vetor contendo o número de tweets coletados de cada dispositivo
num_tweets2 = c(length(tweets_fold), length(tweets_fold[-grep("dope", tweets_fold)]))
# Vetor contendo todos os tweets de cada dispositivo
tweets2 = c(tweets_fold, tweets_fold[-grep("dope", tweets_fold)])

# Calculando score de sentimento
scores2 = calcula_score(tweets2, pos, neg)
# Atribui o dispositivo para os scores
scores2$text = factor(rep(c("Before", "After"), num_tweets2))
# Inclui campos positivo enegativo para contagem de quantas ocorr?ncias h? de cada dispositivo
scores2$positivo = as.numeric(scores2$score >= 1)
scores2$negativo = as.numeric(scores2$score <= -1)
# Calcula o score final de cada dispositivo
scores_finais2 <- data.frame(Versao = c("Before", "After"),
                             Score = c(
                               sum(scores2[scores2$text == "Before", "positivo"]) - sum(scores2[scores2$text == "Before", "negativo"]),
                               sum(scores2[scores2$text == "After", "positivo"]) - sum(scores2[scores2$text == "After", "negativo"])
                             ))
# Plotando gráfico contendo score final de cada dispositivo
ggplot(scores_finais2, aes(x = reorder(Versao, Score), y = Score)) +
  geom_col(aes(fill = Score), alpha = 0.7) +
  ggtitle("Anáise de Scores do Galaxy Fold - Antes x Depois") +
  geom_text(aes(label = Score), size = 3) +
  xlab("Momento") + 
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face="bold"))

# Conforme esperado o score saltaria de -15 para 113, sendo o total de 128 pontos o potencial de
# ganho dentro desta mesma amostragem.

# Classificação de polaridade sem os tweets que contenham a palavra "dope"
# Galaxy Fold
class_polar_fold_after <- classify_polarity(tweets_fold_analysis[-grep("dope", tweets_fold_analysis)], algorithm = "bayes")
polaridade_fold_after <- class_polar_fold_after[, 4]

# Galaxy Fold
resultados_fold_after <- data.frame(
  texto = tweets_fold_analysis[-grep("dope", tweets_fold_analysis)],
  polaridade = polaridade_fold_after,
  stringsAsFactors = FALSE
)

# Apresentação dos resultados de polaridade do Galaxy Fold
plot_pol_fold_after <- ggplot(resultados_fold_after, aes(x = polaridade)) +
  geom_bar(aes(y = ..count.., fill = polaridade)) + 
  scale_fill_brewer(palette = "RdGy") +
  scale_fill_discrete(name = "Polaridades") +
  labs(x = "Categorias", y = "Número de Tweets") +
  ggtitle("Polaridades atribuídas aos tweets sobre Galaxy Fold - Depois") +
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face="bold"),
        plot.background = element_rect(fill = "gray"))

grid.arrange(plot_pol_fold, plot_pol_fold_after, nrow = 2)

# Conforme evidenciado houve uma redução da expectativa negativa com a remoção dos tweets com a
# palavra "dope"

grid.arrange(plot_pol_sten, plot_pol_fold_after, nrow = 2)

# Com este avanço a configuração de polaridade ficou com o mesmo padrão obtido para o Galaxy S10,
# conforme esperado.

data.frame(table(resultados_fold_after$polaridade)) %>%
  mutate(
    Config = round((Freq / sum(Freq))*100, 2)
  )

# A nova configuração possui os seguintes avanços
# NEGATIVIDADE: 10,86% = redução de 12,26%
# NEUTRALIDADE: 17,60% = aumento de 2,44%
# POSITIVIDADE: 71,54% = aumento de 9,82%

# Estes avanços evidenciam um potencial positivo em relação ao objetivo estabelecido

# A segunda palavra com maior frequência é "problems", que embora possa ser genérica, sua 
# contextualização é importante para identificar possíveis padrões a serem estrategicamente
# explorados
grep("problems", tweets_fold, value = TRUE)

# Análise
# Conforme verificado todos os tweets fazem referência a um post que ressalta 5 problemas referente
# ao Galaxy Fold: https://t.co/xUa0Dyqqyp
# Os problemas levantados são:
# Qualidade da tela de plástico quanto ao desgaste com possível estresse do material com os
# movimentos de abre e fecha;
# Espessura e peso elevados;
# Pouca compatibilidade de aplicativos;
# Falta de uma tela meio termo: entre a opção muito pequena quando fechado e a opãoo grande quando
# aberto;
# Preço elevado.
# Todas estas questões são naturais ao lançamento de um conceito. e provenientes da formação 
# dos 4 Ps do Marketing, não dando muita abertura para sugestões pré lançamento. Porém, são
# questões que a Samsung deve considerar estratégicas para garantir a aceitação e prolongar o tempo
# de vida deste produto.

# Contextualizando a palavra "Wild"
grep("wild", tweets_fold, value = TRUE)

# Análise
# Conforme veirificado os tweets se referem a um tweet que questiona o fato do aparelho fechar
# facilmente com uma mão, mas não ser possível de abrir sem utlizar a segunda mão, podendo
# dificultar o manuseio com fechamentos acidentais: https://t.co/YvF4voChBX
# Se tratando de um tweet de um usuário que está com um modelo para teste, uma resposta da empresa
# deve antecipar o lançamento oficial e portanto ser abordado em pré lançaamento.

# Novamente, o potencial resultado com esta ação será calculado removendo os tweets que possuam esta
# palavra.

# Calculando Score sem tweets com as palavras "dope" e "wild"
# Vetor contendo o número de tweets coletados de cada dispositivo
num_tweets2 = c(length(tweets_fold), length(tweets_fold[-grep("dope|wild", tweets_fold)]))
# Vetor contendo todos os tweets de cada dispositivo
tweets2 = c(tweets_fold, tweets_fold[-grep("dope|wild", tweets_fold)])

# Calculando score de sentimento
scores2 = calcula_score(tweets2, pos, neg)
# Atribui o dispositivo para os scores
scores2$text = factor(rep(c("Before", "After"), num_tweets2))
# Inclui campos positivo enegativo para contagem de quantas ocorr?ncias h? de cada dispositivo
scores2$positivo = as.numeric(scores2$score >= 1)
scores2$negativo = as.numeric(scores2$score <= -1)
# Calcula o score final de cada dispositivo
scores_finais2 <- data.frame(Versao = c("Before", "After"),
                             Score = c(
                               sum(scores2[scores2$text == "Before", "positivo"]) - sum(scores2[scores2$text == "Before", "negativo"]),
                               sum(scores2[scores2$text == "After", "positivo"]) - sum(scores2[scores2$text == "After", "negativo"])
                             ))
# Plotando gráfico contendo score final de cada dispositivo
ggplot(scores_finais2, aes(x = reorder(Versao, Score), y = Score)) +
  geom_col(aes(fill = Score), alpha = 0.7) +
  ggtitle("Anáise de Scores do Galaxy Fold - Antes x Depois") +
  geom_text(aes(label = Score), size = 3) +
  xlab("Momento") + 
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face="bold"))

# Conforme esperado o score saltaria de -15 para 122, sendo o total de 137 pontos o potencial de
# ganho dentro desta mesma amostragem.

# Classificação de polaridade sem os tweets que contenham a palavra "dope" e "wild"
# Galaxy Fold
class_polar_fold_after <- classify_polarity(tweets_fold_analysis[-grep("dope|wild", tweets_fold_analysis)], algorithm = "bayes")
polaridade_fold_after <- class_polar_fold_after[, 4]

# Galaxy Fold
resultados_fold_after <- data.frame(
  texto = tweets_fold_analysis[-grep("dope|wild", tweets_fold_analysis)],
  polaridade = polaridade_fold_after,
  stringsAsFactors = FALSE
)

# Apresentação dos resultados de polaridade do Galaxy Fold
plot_pol_fold_after <- ggplot(resultados_fold_after, aes(x = polaridade)) +
  geom_bar(aes(y = ..count.., fill = polaridade)) + 
  scale_fill_brewer(palette = "RdGy") +
  scale_fill_discrete(name = "Polaridades") +
  labs(x = "Categorias", y = "Número de Tweets") +
  ggtitle("Polaridades atribuídas aos tweets sobre Galaxy Fold - Depois") +
  theme(plot.title = element_text(vjust = 0.5, hjust = 0.5, face="bold"),
        plot.background = element_rect(fill = "gray"))

grid.arrange(plot_pol_fold, plot_pol_fold_after, nrow = 2)

# Conforme evidenciado houve uma redução da expectativa negativa com a remoção dos tweets com a
# palavra "dope" e "wild"

grid.arrange(plot_pol_sten, plot_pol_fold_after, nrow = 2)

# Com este avanço a configuração de polaridade ficou com o mesmo padrão obtido para o Galaxy S10,
# conforme esperado.

data.frame(table(resultados_fold_after$polaridade)) %>%
  mutate(
    Config = round((Freq / sum(Freq))*100, 2)
  )

# A nova configuração possui os seguintes avanços
# NEGATIVIDADE: 9,97% = redução de 13,15%
# NEUTRALIDADE: 17,68% = aumento de 2,44%
# POSITIVIDADE: 72,35% = aumento de 10,63%

# Estes avanços evidenciam novamente um potencial positivo em relação ao objetivo estabelecido

# Resumo final
# Foram sugeridas abordagens antes do lançamento para melhor explicação ou desempenho do uso da
# S-PEN, e de uma possível regulagem ou explicação quanto ao manuseio do aparelho com uma única
# mão, quanto à abertura e fechamento.
# Com estas ações foi verificado um potencial de melhoria na polaridade dos tweets de:
# Redução de 13,15% da negatividade
# Aumento de 2,44% da neutralidade
# Aumento de 10,63% da positividade
# Se aproximando assim da polaridade do Galaxy S10 conforme abaixo:
# NEGATIVIDADE: 9,97% contra 9,21% do GS10
# NEUTRALIDADE: 17,68% contra 12,80% do GS10
# POSITIVIDADE: 72,35% contra 77,99% do GS10
# Sendo estas ações condizentes com o objetivo estabelecido do projeto.

# Considerações importantes:
# Este projeto embora simples, demonstra o grande potencial da análise de sentimentos.
# Para uma anáise mais aprimorada deveria haver coleta de diferentes fontes de dados e em diferentes
# períodos, o que enriqueceria a análise com um conjunto significativamente maior de informações.
# Também seria importante dar foco em palavras positivas para compreender os pontos fortes do
# produto, podendo assim trabalhar para maior conquista do público.
# Este tipo de análise no contexto de Negócio, é uma abordagem extremamente eficiente para
# compreender o posicionamento estratégico não só do produto, mas também da empresa, como por
# exemplo para a composição de uma matriz SWOT.
# A análise de sentimento também pode enriquecer tomadas de ações em diferentes modelos de Negócios,
# como por exemplo, utilizar de uma abordagem similar para uma pesquisa de satisfação de
# colaboradores em uma empresa.
