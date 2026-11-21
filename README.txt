TWILIGHT DOWNLOADER - YOUTUBE / YOUTUBE MUSIC / X (TWITTER)
===========================================================

Script em lote (Windows) que usa o yt-dlp para baixar videos, audios,
playlists, albuns e videos do X/Twitter, com capas e legendas.

COMO USAR
1. Extraia a pasta inteira (nao rode de dentro do zip).
2. De dois cliques em TwilightDownloader.bat.
3. Na primeira vez ele pergunta se quer atualizar o yt-dlp (recomendado: S).
4. Cole o link e responda as perguntas.

ARQUIVOS DA PASTA
- TwilightDownloader.bat : o script
- config.txt             : configuracao (criada/atualizada pelo script)
- yt-dlp.exe, ffmpeg.exe, ffprobe.exe : programas usados pelo script
- yt-dlp_x86.exe         : usado so para baixar legendas
- deno\deno.exe          : necessario para o YouTube funcionar
  (se faltar, o script tenta baixar sozinho)
- mapa_audio.txt / mapa_video.txt : criados sozinhos (veja HISTORICO)

TIPOS DE LINK
- YouTube Music (music.youtube.com): baixa somente audio.
- YouTube comum: pergunta se e video unico ou playlist/album/mix, e se quer
  video (mp4) ou so audio (MP3, M4A ou OGG).
- X / Twitter (x.com ou twitter.com): detectado automaticamente. Baixa o
  video bruto em mp4, na melhor qualidade, sem legendas, capa ou metadados.
  Pergunta apenas se deseja usar cookies (necessario para conteudo sensivel).

PASTAS DE DESTINO
- Existe uma pasta padrao para VIDEOS e outra para MUSICAS (audio).
- Na primeira vez de cada tipo o script pergunta o caminho e se deseja
  definir como padrao. Depois disso ele usa a padrao automaticamente.
- No resumo, a opcao [P] permite trocar a pasta daquele download.
- O X/Twitter usa a pasta de videos.

HISTORICO (nao baixar de novo o que ja existe)
- Cada download concluido e anotado em mapa_audio.txt ou mapa_video.txt
  (ID do video + caminho do arquivo).
- Ao baixar uma playlist de novo, so entram os itens que ainda nao estao na
  pasta. Se voce apagar um arquivo, ele e baixado novamente.
- Se renomear ou mover um arquivo, o script nao o encontra e baixa de novo.
- Para zerar o historico, apague os arquivos mapa_*.txt.

CAPAS (PASTA images)
- Playlist: cria a pasta "images" dentro da pasta da playlist, com uma capa
  para cada faixa/video.
- Album do YouTube Music (links com OLAK5uy_ ou MPREb_): somente uma capa,
  cover.jpg.
- Video ou musica unica: a capa fica embutida no arquivo.

COOKIES
- Sao pedidos apenas quando necessario: conteudo de MEMBROS do canal,
  playlist/video PRIVADO na sua conta, ou no X/Twitter (voce escolhe).
- O script identifica os navegadores instalados (Firefox, Chrome, Edge,
  Brave, Opera, Vivaldi). Responda S para usar o detectado, N para nao
  usar, ou digite outro navegador.
- Use um navegador logado na conta certa. O Firefox costuma ser o mais
  confiavel. Se Chrome/Edge der erro de cookies, feche o navegador por
  completo ou use o Firefox.
- Use cookies so quando precisar. Nunca compartilhe seus cookies.

LEGENDAS (somente no modo video)
- Pergunta o idioma: Portugues, Ingles, Japones ou Todas.
- Usa as legendas nativas do video. Se nao existirem, usa as automaticas
  do YouTube. Resultado em arquivos .srt ao lado do video.
- Opcao Todas: baixa todas as nativas. Em video unico, se nao houver nenhuma,
  baixa a automatica do idioma original. Em playlist, a automatica do idioma
  original e baixada tambem.
- Usa yt-dlp_x86.exe e conexao IPv4 para evitar os erros "curl: (7)" e
  "curl: (45)" do cliente curl embutido no yt-dlp.exe.

PARAMETROS DO config.txt
Uma opcao por linha, no formato nome=valor, sem aspas. Linhas com # sao
comentarios.

  defaultVideoFolder  Pasta padrao de VIDEOS. Vazio = perguntar.
  defaultMusicFolder  Pasta padrao de MUSICAS. Vazio = perguntar.
  threads             Downloads de fragmentos em paralelo (-N). Padrao: 4.
  subsExe             Executavel usado nas legendas. Padrao: yt-dlp_x86.exe.
  sleepSubs           Segundos de pausa entre legendas. Padrao: 5.
  langPt              Codigos de idioma para Portugues. Padrao: pt,pt-BR
  langEn              Codigos para Ingles. Padrao: en,en-US,en-GB
  langJa              Codigos para Japones. Padrao: ja
  updateAsked         1 = ja perguntou sobre atualizar. Use 0 para perguntar
                      de novo na proxima abertura.

PROBLEMAS COMUNS
- "HTTP Error 429": o YouTube limitou os pedidos. Espere e tente de novo,
  ou aumente sleepSubs.
- "Requested format is not available": falta o deno ou o yt-dlp esta
  desatualizado. Rode: yt-dlp -U
- Erros curl nas legendas: confirme que yt-dlp_x86.exe esta na pasta e
  atualize-o com: yt-dlp_x86.exe -U
- X/Twitter: "No video could be found in this tweet" em conteudo sensivel
  significa que e preciso usar cookies de um navegador logado no X.
- Videos de membros: use os cookies de um navegador logado no YouTube com
  a assinatura do nivel exigido.
