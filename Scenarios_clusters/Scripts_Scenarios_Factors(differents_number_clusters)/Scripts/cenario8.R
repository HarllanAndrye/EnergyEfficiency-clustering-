#
# Cenário 8: Características + NIALM + Perfil
#     -> Latitude, Longitude, Consumo, Aparelhos[], similaridade[]
#

source("functions.R")

# Caminho para armazenar os resultados
resultsData <- "../Results/Data/cenario8/"
resultsImages <- "../Results/Images/"

# Quantidade de execuções
qtdExecucoes <- 30


for(numberClusters in 3:8){ # Quantidade de clusters
  print(paste("Qtd cluster = ", numberClusters, sep = ""))
  # Número da execução
  execucao = 1
  # Definição do nome dos arquivos que os resultados da execuções vão ser armazenados
  nomeArquivo2 = paste(resultsData, numberClusters, "/dados_exec", execucao, ".csv", sep="") # Usuários
  
  #---------------------------
  # 1) pre-processa os dados
  #---------------------------
  # Arquivo com os dados dos usuários
  dados = read.csv("../Database/Questionario(algoritmo_mapeado).csv",  header=T,sep=",")
  
  # ******************************************************************************** #
  # Pegando os perfis e calculando a similaridade entre eles
  # Usado a distãncia euclidiana como medida de similaridade, devido aos resultados anteriores, 
  #   comparando várias medidades,a euclidiana foi melhor.
  # ...
  
  # Caminho de todos arquivos (perfis)
  arquivos <- as.character(dados[,ncol(dados)])
  for(x in 1:length(arquivos)){
    arquivos[x] <- paste("../", arquivos[x], sep = "")
  }
  
  # Colocando todos os dados em uma tabela
  # 1 dia (média)
  for(i in 1:(length(arquivos))){
    # Lendo 1 arquivo
    u <- read.csv(arquivos[i], header = TRUE, sep = ",")
  
    # Obtendo apenas 1 dia, calculando a média das horas
    u$date <- substr(u[ ,1],12,13) # Retirando o dia
    u <- aggregate(u[,2], list("date" = u[,1]), FUN = mean)
    u <- data.frame(date=u$date, consumption=u$x)
    u <- normDataPerfil(u) # Normalizando o consumo
    
    # colocando na tabela
    if( i==1 ){ # No 1º passo recebe "date" e "consumption"
      series <- u
    } else { # Depois, apenas o "consumption"
      series <- cbind(series, u[,2])
    }
  }
  # Renomeando as colunas
  collNames <- c("date")
  for(i in 1:length(arquivos)){
    column <- paste("user", i, sep = "")
    collNames <- cbind(collNames, column)
  }
  colnames(series) <- collNames
  
  # Similaridade (Euclidiana)
  tam <- ncol(series)-1 # -1 pq não conta com a coluna "date"
  matrizSim <- matrix(data = 0, nrow = tam, ncol = tam)
  for(i in 1:tam){
    p1 <- series[,colnames(series) == paste("user", i, sep = "") ]
    
    for(j in 1:tam){
      p2 <- series[,colnames(series) == paste("user", j, sep = "") ]
      matrizSim[i,j] <- EuclideanDistance(p1, p2)
    }
  }
  matrizSim <- as.data.frame(matrizSim)
  colnames(matrizSim) <- collNames[-1]
  # ******************************************************************************** #
  
  dados$X <- seq(1:nrow(dados))
  dados2 = dados
  dados$Bairro <- dados$Valor_conta <- dados$X <- dados$Perfil <- NULL
  rownames(dados) <- dados2$X
  
  # Alterando as informações dos aparelhos: deixar com 0 (não possui) ou 1 (possui).
  for(i in 4:ncol(dados)){
    dados[which(dados[i] > 0), i] <- 1
  }
  
  dadosOrig <- dados2 # Dados iniciais do arquivo .csv
  
  # Unir os dados da similaridade com os dados do questionário
  dados <- cbind(dados, matrizSim)
  
  
  
  #---------------------------
  # 2) agrupamento dos dados
  #---------------------------
  normDados = normData(dados)
  cl <- kmeans(normDados, numberClusters, nstart = 200)
  normDados$cluster = cl$cluster
  
  # Salvando os resultados em um arquivo .csv
  dados2 = dados
  dados2$cluster = cl$cluster
  write.csv(dados2, nomeArquivo2)
  
  Dist <- dist(normDados[,-(ncol(normDados))], method = "euclidean")
  # Cálculo do Dunn Index
  d <- c()
  d = rbind(d, dunn(Dist,cl$cluster))
  
  # Cálculo da Silhueta
  s <- c()
  s <- rbind(s, cluster.stats(Dist, cl$cluster)$avg.silwidth)
  
  
  #---------------------------
  # Demais execuções
  #---------------------------
  for(execucao in 2:qtdExecucoes){
    #print(execucao)
    nomeArquivo2 = paste(resultsData, numberClusters, "/dados_exec", execucao, ".csv", sep="")
  
    # 2) agrupamento dos dados
    normDados = normData(dados)
    cl <- kmeans(normDados, numberClusters, nstart = 200)
    normDados$cluster = cl$cluster
  
    # Salvando os resultados em um arquivo .csv
    dados2 = dados
    dados2$cluster = cl$cluster
    write.csv(dados2, nomeArquivo2)
    
    Dist <- dist(normDados[,-(ncol(normDados))], method = "euclidean")
    # Cálculo do Dunn Index
    d = rbind(d, dunn(Dist,cl$cluster))
  
    # Cálculo da Silhueta
    s <- rbind(s, cluster.stats(Dist, cl$cluster)$avg.silwidth)
  }
  
  # Dunn e Silhouette
  write.csv(d, file = paste(resultsData, numberClusters, "/dunn.csv", sep = ""))
  write.csv(s, file = paste(resultsData, numberClusters, "/silhouette.csv", sep = ""))
  
  png(file = paste(resultsImages, numberClusters, "/cenario8_metricas.png", sep = ""), width = 1110, height = 611)
  par(mfrow=c(1,2))
  plot(d, type = 'l', xlab = "Execuções", ylab = "Dunn Index", main = "Cenário 8", las=1)
  plot(s, type = 'l', xlab = "Execuções", ylab = "Silhouette Width", main = "Cenário 8", las=1)
  dev.off()
  
  write(paste(numberClusters, " clusters, Dunn = ", d[qtdExecucoes], sep = ""), paste(resultsData, "dunn_cenario8.txt", sep = ""), 
        append=TRUE)
  write(paste(numberClusters, " clusters, Silhouette = ", s[qtdExecucoes], sep = ""), paste(resultsData, "silhouette_cenario8.txt", sep = ""), 
        append=TRUE)
  
  
  # ------------------------------ Grupos formados ------------------------------ #
  exec1 <- read.csv(paste(resultsData, numberClusters, "/dados_exec1.csv", sep = ""))
  gg1 <- ggplot(exec1, aes(Longitude, Latitude, col=factor(cluster))) + geom_point(size = 4) + 
    labs(title="Cenário 8 - exec. 1", x="Longitude", y="Latitude") + 
    scale_colour_discrete(name = "Grupos") + 
    geom_text(aes(Longitude, Latitude+0.003, label=X))
  
  exec30 <- read.csv(paste(resultsData, numberClusters, "/dados_exec30.csv", sep = ""))
  gg2 <- ggplot(exec30, aes(Longitude, Latitude, col=factor(cluster))) + geom_point(size = 4) + 
    labs(title="Cenário 8 - exec. 30", x="Longitude", y="Latitude") + 
    scale_colour_discrete(name = "Grupos") + 
    geom_text(aes(Longitude, Latitude+0.003, label=X))
  
  png(file = paste(resultsImages, numberClusters, "/cenario8_grupos.png", sep = ""), width = 1350, height = 550)
  grid.arrange(gg1, gg2, ncol = 2)
  dev.off()
  
  
  write(paste("-- Quantidade = ", numberClusters, " --", sep = ""), paste(resultsData, "grupos_cenario8.txt", sep = ""), append=TRUE)
  # Grupos - Última execução
  qtdCluster <- max(exec30$cluster)
  for(i in 1:qtdCluster){
    #print(which(exec30$cluster == i))
    # Escrevendo no arquivo...
    write(which(exec30$cluster == i), paste(resultsData, "grupos_cenario8.txt", sep = ""), append=TRUE, ncolumns = 50)
  }
  write("", paste(resultsData, "grupos_cenario8.txt", sep = ""), append=TRUE) # para pular linha
  
  
  
  
  # Perfis agrupados
  series_ <- series[-1]
  png(file = paste(resultsImages, numberClusters, "/cenario8_grupos_perfis.png", sep = ""), width = 1350, height = 550)
  
  # mfrow=c(nr, nc) -- number row, number column
  if(numberClusters == 3){
    par(mfrow=c(1,3))
  } else if(numberClusters == 4){
    par(mfrow=c(2,2))
  } else if(numberClusters == 5 || numberClusters == 6){
    par(mfrow=c(2,3))
  } else if(numberClusters == 7 || numberClusters == 8){
    par(mfrow=c(2,4))
  }
  
  for (i in 1:qtdCluster) {
    cluster = which(exec30$cluster == i)
    matplot(matrix(seq(1,24,1),ncol=1),series_[,cluster],type='l',
            ylab='Consumo',xlab='Horas',main=paste('cluster',i),cex.main=1.5,cex.axis=1.5,
            col=1, lty=1)
  }
  dev.off()
  
  write(paste(numberClusters, " clusters, MAE = ", maeSeries(series_, exec30$cluster, qtdCluster), sep = ""), 
        paste(resultsData, "mae_cenario8.txt", sep = ""), append=TRUE)
}



