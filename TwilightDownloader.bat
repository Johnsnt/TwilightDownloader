@echo off
chcp 65001 >nul
setlocal EnableExtensions
title Baixador YouTube / YouTube Music

REM A pasta do script entra no PATH (yt-dlp.exe, ffmpeg.exe e ffprobe.exe podem ficar ao lado do .bat)
set "PATH=%~dp0;%PATH%"

where yt-dlp >nul 2>&1 || (echo yt-dlp nao encontrado no PATH nem na pasta do script. & pause & exit /b)

REM ============================================================
REM  FFmpeg + FFprobe (necessarios; baixados na pasta do script
REM  se nao existirem, do build oficial recomendado pelo yt-dlp:
REM  github.com/yt-dlp/FFmpeg-Builds)
REM ============================================================
where ffmpeg >nul 2>&1 && where ffprobe >nul 2>&1 && goto ffok

echo.
echo FFmpeg/FFprobe nao encontrados. Baixando em "%~dp0" ^(cerca de 160 MB, aguarde^) ...
set "FFZIP=%~dp0ffmpeg.zip"
set "FFTMP=%~dp0ffmpeg_tmp"
set "FFDIR=ffmpeg-master-latest-win64-gpl"
if exist "%FFTMP%" rmdir /s /q "%FFTMP%" >nul 2>&1
mkdir "%FFTMP%"
curl.exe -L --fail -o "%FFZIP%" "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/%FFDIR%.zip"
if errorlevel 1 goto fffalha
tar -xf "%FFZIP%" -C "%FFTMP%" "%FFDIR%/bin/ffmpeg.exe" "%FFDIR%/bin/ffprobe.exe" >nul 2>&1
if not exist "%FFTMP%\%FFDIR%\bin\ffprobe.exe" powershell -NoProfile -Command "Expand-Archive -LiteralPath $env:FFZIP -DestinationPath $env:FFTMP -Force"
copy /y "%FFTMP%\%FFDIR%\bin\ffmpeg.exe" "%~dp0ffmpeg.exe" >nul 2>&1
copy /y "%FFTMP%\%FFDIR%\bin\ffprobe.exe" "%~dp0ffprobe.exe" >nul 2>&1
rmdir /s /q "%FFTMP%" >nul 2>&1
del "%FFZIP%" >nul 2>&1
if not exist "%~dp0ffmpeg.exe" goto fffalha
if not exist "%~dp0ffprobe.exe" goto fffalha
echo FFmpeg e FFprobe instalados com sucesso.
goto ffok

:fffalha
if exist "%FFTMP%" rmdir /s /q "%FFTMP%" >nul 2>&1
if exist "%FFZIP%" del "%FFZIP%" >nul 2>&1
echo.
echo ERRO: nao consegui baixar o FFmpeg automaticamente.
echo       Baixe manualmente em https://github.com/yt-dlp/FFmpeg-Builds/releases/latest
echo       ^(arquivo %FFDIR%.zip^) e copie ffmpeg.exe e ffprobe.exe da pasta "bin"
echo       para "%~dp0".
pause
exit /b
:ffok

REM ============================================================
REM  Configuracao (config.txt na mesma pasta deste script)
REM ============================================================
set "CFG=%~dp0config.txt"
set "DFV="
set "DFM="
set "THREADS=4"
set "SUBEXE=yt-dlp_x86.exe"
set "SLEEPSUB=5"
set "LANGPT=pt,pt-BR"
set "LANGEN=en,en-US,en-GB"
set "LANGJA=ja"
set "UPDASK=0"
if exist "%CFG%" for /f "usebackq eol=# delims=" %%L in ("%CFG%") do set "LINE=%%L" & call :cfg

REM ============================================================
REM  Deno (necessario para o YouTube; instalado na pasta "deno"
REM  ao lado deste script, sem mexer no sistema)
REM ============================================================
set "DENODIR=%~dp0deno"
if exist "%DENODIR%\deno.exe" set "PATH=%DENODIR%;%PATH%"
where deno >nul 2>&1 && goto denook

echo.
echo Deno nao encontrado. Instalando em "%DENODIR%" ...
if not exist "%DENODIR%" mkdir "%DENODIR%"
curl.exe -L --fail -o "%DENODIR%\deno.zip" "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip"
if errorlevel 1 goto denofalha
tar -xf "%DENODIR%\deno.zip" -C "%DENODIR%" >nul 2>&1
if not exist "%DENODIR%\deno.exe" powershell -NoProfile -Command "Expand-Archive -LiteralPath $env:DENODIR'\deno.zip' -DestinationPath $env:DENODIR -Force"
del "%DENODIR%\deno.zip" >nul 2>&1
if not exist "%DENODIR%\deno.exe" goto denofalha
set "PATH=%DENODIR%;%PATH%"
echo Deno instalado com sucesso.
goto denook

:denofalha
echo.
echo AVISO: nao consegui instalar o Deno automaticamente.
echo        O YouTube pode falhar. Baixe manualmente em https://github.com/denoland/deno/releases/latest
echo        e coloque o deno.exe na pasta "%DENODIR%".
pause
:denook

REM Argumentos de JS para TODAS as chamadas do yt-dlp:
REM  - usa o Deno para resolver o desafio "n" do YouTube
REM  - baixa o solver (EJS) do GitHub caso a sua versao do yt-dlp nao o tenha embutido
set "JS=--js-runtimes deno --remote-components ejs:github"

REM ============================================================
REM  Primeira execucao: perguntar se deseja atualizar o yt-dlp
REM ============================================================
if "%UPDASK%"=="1" goto updok
echo.
choice /c SN /n /m "Primeira execucao: deseja atualizar o yt-dlp agora? [S/N] "
set "UPDR=%errorlevel%"
set "UPDASK=1"
call :salvar
if "%UPDR%"=="1" call :atualizar
:updok

:inicio
cls
for %%v in (URL T C F S PL WT CK DET LS SL SK SN MEMB TIPO FMT CAPA AF AK AFN P TW PRIV) do set "%%v="
set /p "URL=Cole o link da mídia (YouTube, YouTube Music ou x.com): "
if not defined URL goto inicio

REM ---------- Deteccao: YouTube Music e album ----------
set "M=0"
set "X=%URL:music.youtube.com=%"
if not "%X%"=="%URL%" set "M=1"
set "AL=0"
set "X=%URL:OLAK5uy_=%"
if not "%X%"=="%URL%" set "AL=1"
set "X=%URL:MPREb_=%"
if not "%X%"=="%URL%" set "AL=1"

REM ---------- Deteccao: Twitter / X ----------
set "TW=0"
set "X=%URL:/x.com/=%"
if not "%X%"=="%URL%" set "TW=1"
set "X=%URL:.x.com/=%"
if not "%X%"=="%URL%" set "TW=1"
set "X=%URL:/twitter.com/=%"
if not "%X%"=="%URL%" set "TW=1"
set "X=%URL:.twitter.com/=%"
if not "%X%"=="%URL%" set "TW=1"
if "%TW%"=="1" goto twitterinfo

set /p "T=Link e: [1] Video/musica unica  [2] Playlist/Album/Mix : "
set "PL=--no-playlist"
if "%T%"=="2" set "PL=--yes-playlist"

REM ---------- Formato ----------
set "F=2"
if "%M%"=="1" echo YouTube Music detectado: baixando somente audio.
if "%M%"=="0" set /p "F=Baixar: [1] Video  [2] So audio : "

REM ---------- Formato do audio (so quando for audio) ----------
set "AF=mp3"
set "AFN=MP3"
if "%F%"=="1" goto semaudiofmt
echo.
echo Formato do audio:  [1] MP3  [2] M4A (MPEG-4 Audio)  [3] OGG (Vorbis)
choice /c 123 /n /m "Escolha: "
set "AK=%errorlevel%"
if "%AK%"=="2" set "AF=m4a"
if "%AK%"=="2" set "AFN=M4A (MPEG-4 Audio)"
if "%AK%"=="3" set "AF=vorbis"
if "%AK%"=="3" set "AFN=OGG (Vorbis)"
:semaudiofmt

REM ---------- Legendas (perguntadas ANTES de baixar o video) ----------
set "SK=1"
set "SN=Nao"
set "S=n"
if not "%F%"=="1" goto semsubs
echo.
echo Legendas:  [1] Nenhuma  [2] Portugues  [3] Ingles  [4] Japones  [5] Todas
choice /c 12345 /n /m "Escolha: "
set "SK=%errorlevel%"
if "%SK%"=="2" set "SL=%LANGPT%"
if "%SK%"=="2" set "SN=Portugues - %LANGPT%"
if "%SK%"=="3" set "SL=%LANGEN%"
if "%SK%"=="3" set "SN=Ingles - %LANGEN%"
if "%SK%"=="4" set "SL=%LANGJA%"
if "%SK%"=="4" set "SN=Japones - %LANGJA%"
if "%SK%"=="5" set "SN=Todas (nativas; sem nativas, automatica original)"
if not "%SK%"=="1" set "S=s"
:semsubs

REM ---------- Twitter / X: sem perguntas extras ----------
goto membros
:twitterinfo
echo Twitter/X detectado: video mp4 na melhor qualidade, sem perguntas extras.
set "T=1"
set "F=1"
set "PL="
set "S=n"
set "SK=1"
set "SN=Nao"
set "MEMB=0"
set "CK="
echo.
choice /c SN /n /m "Usar cookies do navegador? Necessario para acessar conteúdo sensível [S/N] "
if errorlevel 2 goto semck
call :twitterck
goto semck

:membros
REM ---------- Verifica se o conteudo e de MEMBROS do canal ----------
set "MEMB=0"
set "PRIV=0"
echo.
echo Verificando se o conteudo e de membros ou privado...
set "TMPAV=%TEMP%\baixador_av.txt"
yt-dlp %JS% %PL% --playlist-items 1 --simulate --ignore-no-formats-error --print availability "%URL%" >"%TMPAV%" 2>&1
findstr /i /c:"subscriber_only" /c:"members-only" /c:"members only" /c:"Join this channel" "%TMPAV%" >nul 2>&1 && set "MEMB=1"
REM Playlist/video privado: sem login o YouTube responde "playlist does not exist", "playlist is private" ou "Private video"
findstr /i /c:"playlist does not exist" /c:"playlist is private" /c:"private playlist" /c:"Private video" /c:"granted access" "%TMPAV%" >nul 2>&1 && set "PRIV=1"
del "%TMPAV%" >nul 2>&1
if "%MEMB%"=="1" goto precisack
if "%PRIV%"=="1" goto precisack
echo Conteudo publico: cookies nao necessarios.
goto semck

REM ---------- Cookies (conteudo de membros ou privado) ----------
:precisack
echo.
if "%PRIV%"=="1" echo Conteudo PRIVADO detectado: playlist ou video privado na sua conta. E preciso o login do navegador.
if "%PRIV%"=="0" echo Conteudo de MEMBROS detectado. E preciso o login do navegador.
if exist "%APPDATA%\Mozilla\Firefox\Profiles" set "LS=%LS% firefox"
if exist "%LOCALAPPDATA%\Google\Chrome\User Data" set "LS=%LS% chrome"
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data" set "LS=%LS% edge"
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" set "LS=%LS% brave"
if exist "%APPDATA%\Opera Software\Opera Stable" set "LS=%LS% opera"
if exist "%LOCALAPPDATA%\Vivaldi\User Data" set "LS=%LS% vivaldi"
for %%a in (%LS%) do if not defined DET set "DET=%%a"
if defined DET goto perguntack
echo Nenhum navegador identificado.
set /p "C=Usar cookies de qual navegador? (digite o nome ou Enter para nao usar): "
if defined C set "CK=--cookies-from-browser %C%"
goto semck
:perguntack
echo Navegadores identificados:%LS%
set /p "C=Usar cookies do navegador %DET%? (S/N ou digite outro navegador - Firefox | Chrome | Edge | Brave | Opera | Vivaldi): "
if /i "%C%"=="s" set "CK=--cookies-from-browser %DET%"
if /i not "%C%"=="s" if /i not "%C%"=="n" if defined C set "CK=--cookies-from-browser %C%"
:semck

REM ============================================================
REM  Pasta de destino: uma padrao para VIDEOS e outra para MUSICAS
REM  (F=1 = video; qualquer outro valor = audio/musica)
REM ============================================================
set "P="
if "%F%"=="1" goto pastavideo
if defined DFM if exist "%DFM%\" set "P=%DFM%"
goto pastachk
:pastavideo
if defined DFV if exist "%DFV%\" set "P=%DFV%"
:pastachk
if defined P goto pastaok

:perguntapasta
set "P="
echo.
if "%F%"=="1" echo --- Pasta para VIDEOS ---
if not "%F%"=="1" echo --- Pasta para MUSICAS ---
set /p "P=Em qual pasta deseja salvar? (caminho completo): "
if not defined P goto perguntapasta
set "P=%P:"=%"
if "%P:~-1%"=="\" set "P=%P:~0,-1%"
if not exist "%P%\" mkdir "%P%" 2>nul
if not exist "%P%\" echo Pasta invalida ou sem permissao. Tente outra.& goto perguntapasta
if "%F%"=="1" choice /c SN /n /m "Definir esta pasta como padrao para VIDEOS? [S/N] "
if not "%F%"=="1" choice /c SN /n /m "Definir esta pasta como padrao para MUSICAS? [S/N] "
if errorlevel 2 goto pastaok
if "%F%"=="1" set "DFV=%P%"
if not "%F%"=="1" set "DFM=%P%"
call :salvar
echo Pasta padrao salva em %CFG%

:pastaok
set "P=%P:"=%"
if "%P:~-1%"=="\" set "P=%P:~0,-1%"

REM ============================================================
REM  Textos do resumo
REM ============================================================
set "TIPO=Video/musica unica"
if "%T%"=="2" set "TIPO=Playlist/Mix"
if "%T%"=="2" if "%AL%"=="1" set "TIPO=Album do YouTube Music"

if "%F%"=="1" set "FMT=Video mp4 - melhor qualidade disponivel (video + audio)"
if not "%F%"=="1" set "FMT=Audio %AFN% - melhor qualidade"

set "CAPA=Capa embutida no arquivo"
if "%T%"=="2" set "CAPA=1 capa por faixa na pasta images"
if "%T%"=="2" if "%AL%"=="1" set "CAPA=1 capa do album (images\cover.jpg)"

:resumo
cls
if "%TW%"=="1" goto resumotw
echo ==================== RESUMO ====================
call :linha "Link" "%URL%"
echo Tipo ......: %TIPO%
echo Formato ...: %FMT%
echo Capas .....: %CAPA%
echo Legendas ..: %SN%
if "%MEMB%"=="1" echo Membros ...: sim
if "%MEMB%"=="0" echo Membros ...: nao
if "%PRIV%"=="1" echo Privado ...: sim
if "%PRIV%"=="0" echo Privado ...: nao
if defined CK echo Cookies ...: %CK%
if not defined CK echo Cookies ...: nao usar
call :linha "Pasta" "%P%"
echo ================================================
goto resumoescolha

:resumotw
echo ==================== RESUMO ====================
call :linha "Link" "%URL%"
echo Origem ....: Twitter / X
echo Formato ...: Video mp4 - melhor qualidade disponivel (bruto, sem recodificar)
echo Extras ....: sem legendas, sem capa, sem metadados
if defined CK echo Cookies ...: %CK%
if not defined CK echo Cookies ...: nao usar
call :linha "Pasta" "%P%"
echo ================================================

:resumoescolha
echo.
choice /c CRP /n /m "[C] Confirmar e baixar   [R] Cancelar e tentar de novo   [P] Trocar pasta: "
if errorlevel 3 goto perguntapasta
if errorlevel 2 goto inicio

if "%TW%"=="1" goto twitter
if not "%F%"=="1" goto audio
goto video

REM ============================================================
REM  TWITTER / X (video bruto em mp4, melhor qualidade)
REM  - -f "bv*+ba/b": melhor video + melhor audio (ou o melhor arquivo unico)
REM  - --merge-output-format mp4 / --remux-video mp4: garante mp4 sem recodificar
REM  - sem legendas, sem capa, sem metadados embutidos
REM  - nome: usuario - id_do_tweet.mp4
REM  - se falhar (ex.: conteudo sensivel/+18 exige login no X), oferece
REM    tentar de novo com os cookies do navegador
REM ============================================================
:twitter
set "O=%%(uploader_id,uploader|twitter)s - %%(id)s.%%(ext)s"
:twitterrun
yt-dlp %JS% %CK% %PL% -f "bv*+ba/b" --merge-output-format mp4 --remux-video mp4 --windows-filenames -N %THREADS% -P "%P%" -o "%O%" "%URL%"
if not errorlevel 1 goto fim
if defined CK call :erro & goto fim
echo.
echo [AVISO] Falhou sem login. Videos de conteudo sensivel/+18 so aparecem para
echo         contas logadas no X. Usar os cookies do navegador costuma resolver.
choice /c SN /n /m "Tentar de novo com os cookies do navegador (logado no X)? [S/N] "
if errorlevel 2 call :erro & goto fim
call :twitterck
if not defined CK goto fim
goto twitterrun

REM ============================================================
REM  VIDEO
REM ============================================================
:video
set "O=%%(title)s.%%(ext)s"
set "TO=thumbnail:%%(title)s.%%(ext)s"
if "%T%"=="2" set "O=%%(playlist_title)s/%%(playlist_index)03d - %%(title)s.%%(ext)s"
if "%T%"=="2" set "TO=thumbnail:%%(playlist_title)s/images/%%(playlist_index)03d - %%(title)s.%%(ext)s"
if "%T%"=="2" set "WT=--write-thumbnail"
set "MAPA=%~dp0mapa_video.txt"
set "ARQ=%TEMP%\baixador_arq_video.txt"
call :preparar
yt-dlp %JS% %CK% %PL% -t mp4 --embed-metadata --embed-thumbnail %WT% --convert-thumbnails jpg --download-archive "%ARQ%" --print-to-file "after_move:%%(extractor)s %%(id)s|%%(filepath)s" "%MAPA%" --windows-filenames -N %THREADS% -P "%P%" -o "%O%" -o "%TO%" "%URL%"
if errorlevel 1 call :erro
if /i not "%S%"=="s" goto fim
goto legendas

REM ============================================================
REM  AUDIO
REM ============================================================
:audio
set "O=%%(artist,uploader)s - %%(title)s.%%(ext)s"
set "TO=thumbnail:%%(artist,uploader)s - %%(title)s.%%(ext)s"
if "%T%"=="2" set "O=%%(playlist_title)s/%%(playlist_index)02d - %%(artist,uploader)s - %%(title)s.%%(ext)s"
REM Playlist comum: 1 capa por faixa na pasta images
if "%T%"=="2" set "TO=thumbnail:%%(playlist_title)s/images/%%(playlist_index)02d - %%(title)s.%%(ext)s"
REM Album do YouTube Music: somente 1 capa na pasta images
if "%T%"=="2" if "%AL%"=="1" set "TO=thumbnail:%%(playlist_title)s/images/cover.%%(ext)s"
if "%T%"=="2" set "WT=--write-thumbnail"
set "MAPA=%~dp0mapa_audio.txt"
set "ARQ=%TEMP%\baixador_arq_audio.txt"
call :preparar
yt-dlp %JS% %CK% %PL% -x --audio-format %AF% --audio-quality 0 --embed-metadata --embed-thumbnail %WT% --convert-thumbnails jpg --ppa "ThumbnailsConvertor+ffmpeg_o:-vf crop=ih:ih" --download-archive "%ARQ%" --print-to-file "after_move:%%(extractor)s %%(id)s|%%(filepath)s" "%MAPA%" --windows-filenames -N %THREADS% -P "%P%" -o "%O%" -o "%TO%" "%URL%"
if errorlevel 1 call :erro
goto fim

REM ============================================================
REM  LEGENDAS (idioma ja escolhido no inicio)
REM  - Usa as legendas nativas (feitas pelo autor) do idioma escolhido.
REM  - Se nao existirem, usa as automaticas do YouTube.
REM  - Roda com o yt-dlp_x86.exe, que nao tem o cliente curl embutido
REM    que causa os erros "curl: (7)" e "curl: (45)".
REM ============================================================
:legendas
set "SE=%SUBEXE%"
if exist "%~dp0%SE%" set "SE=%~dp0%SE%" & goto exeok
where "%SE%" >nul 2>&1 && goto exeok
echo.
echo [INFO] %SE% nao encontrado.
echo        O yt-dlp.exe comum usa um cliente curl embutido que falha em alguns
echo        PCs ao baixar legendas. O yt-dlp_x86.exe oficial nao usa esse cliente.
choice /c SN /n /m "Baixar o yt-dlp_x86.exe do GitHub oficial nesta pasta agora? [S/N] "
if errorlevel 2 goto exepadrao
curl.exe -L --fail -o "%~dp0yt-dlp_x86.exe" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_x86.exe"
if errorlevel 1 goto exefalha
set "SE=%~dp0yt-dlp_x86.exe"
goto exeok
:exefalha
if exist "%~dp0yt-dlp_x86.exe" del "%~dp0yt-dlp_x86.exe" >nul 2>&1
echo Nao consegui baixar. Baixe manualmente em https://github.com/yt-dlp/yt-dlp/releases/latest
:exepadrao
echo Usando o yt-dlp comum para as legendas (pode dar erro curl).
set "SE=yt-dlp"
:exeok

echo.
echo === Legendas usando %SE% ===
if "%SK%"=="5" goto subtodas

REM ---- Um idioma: o yt-dlp prefere a nativa e so usa a automatica se nao houver ----
"%SE%" %JS% -4 %CK% %PL% --skip-download --ignore-no-formats-error --write-subs --write-auto-subs --sub-langs "%SL%" --convert-subs srt --sleep-subtitles %SLEEPSUB% --sleep-requests 1 --retries 3 --extractor-retries 3 --windows-filenames -P "%P%" -o "%O%" "%URL%"
if errorlevel 1 call :erro
goto fim

REM ---- Todas: nativas de todos os idiomas; sem nativas, so a automatica do idioma original ----
:subtodas
call :contar
set "C0=%CNT%"
"%SE%" %JS% -4 %CK% %PL% --skip-download --ignore-no-formats-error --write-subs --sub-langs "all,-live_chat" --convert-subs srt --sleep-subtitles %SLEEPSUB% --sleep-requests 1 --retries 3 --extractor-retries 3 --windows-filenames -P "%P%" -o "%O%" "%URL%"
if not "%T%"=="2" call :contar
if not "%T%"=="2" if not "%CNT%"=="%C0%" goto fim
echo.
echo Sem legendas nativas (ou playlist): buscando a automatica do idioma original...
"%SE%" %JS% -4 %CK% %PL% --skip-download --ignore-no-formats-error --write-auto-subs --sub-langs ".*-orig" --convert-subs srt --sleep-subtitles %SLEEPSUB% --sleep-requests 1 --retries 3 --extractor-retries 3 --windows-filenames -P "%P%" -o "%O%" "%URL%"

:fim
echo.
set /p "R=Concluido. Baixar outro? (s/n): "
if /i "%R%"=="s" goto inicio
exit /b

REM ============================================================
REM  Sub-rotinas
REM ============================================================
:preparar
REM Historico "inteligente": o mapa guarda "youtube ID|caminho do arquivo".
REM A cada execucao, so entram no historico temporario os itens cujo arquivo AINDA existe.
REM Se voce apagou a musica/video da pasta, ele sai do historico e e baixado de novo.
type nul >"%ARQ%"
if exist "%MAPA%" for /f "usebackq tokens=1,* delims=|" %%a in ("%MAPA%") do if exist "%%b" >>"%ARQ%" echo %%a
exit /b

:linha
<nul set /p "=%~1 ......: %~2"
echo.
exit /b

:twitterck
set "CK="
set "LS="
set "DET="
set "C="
if exist "%APPDATA%\Mozilla\Firefox\Profiles" set "LS=%LS% firefox"
if exist "%LOCALAPPDATA%\Google\Chrome\User Data" set "LS=%LS% chrome"
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data" set "LS=%LS% edge"
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" set "LS=%LS% brave"
if exist "%APPDATA%\Opera Software\Opera Stable" set "LS=%LS% opera"
if exist "%LOCALAPPDATA%\Vivaldi\User Data" set "LS=%LS% vivaldi"
for %%a in (%LS%) do if not defined DET set "DET=%%a"
if defined DET goto twck1
echo Nenhum navegador identificado.
set /p "C=Usar cookies de qual navegador? (digite o nome ou Enter para cancelar): "
if defined C set "CK=--cookies-from-browser %C%"
exit /b
:twck1
echo Navegadores identificados:%LS%
set /p "C=Usar cookies do navegador %DET%? (S/N ou digite outro navegador - Firefox | Chrome | Edge | Brave | Opera | Vivaldi): "
if /i "%C%"=="s" set "CK=--cookies-from-browser %DET%"
if /i not "%C%"=="s" if /i not "%C%"=="n" if defined C set "CK=--cookies-from-browser %C%"
exit /b

:erro
echo.
echo [ERRO] O yt-dlp terminou com erro. Leia as mensagens acima.
echo        Dicas: feche o navegador dos cookies se der erro de banco de dados,
echo        e confira se o Deno esta instalado ^(pasta "deno"^).
exit /b

:atualizar
echo.
echo Atualizando yt-dlp...
yt-dlp -U
if exist "%~dp0%SUBEXE%" echo Atualizando %SUBEXE%...
if exist "%~dp0%SUBEXE%" "%~dp0%SUBEXE%" -U
echo.
exit /b

:cfg
set "LINE=%LINE:"=%"
if /i "%LINE:~0,19%"=="defaultVideoFolder=" set "DFV=%LINE:~19%"
if /i "%LINE:~0,19%"=="defaultMusicFolder=" set "DFM=%LINE:~19%"
if /i "%LINE:~0,8%"=="threads=" set "THREADS=%LINE:~8%"
if /i "%LINE:~0,8%"=="subsExe=" set "SUBEXE=%LINE:~8%"
if /i "%LINE:~0,10%"=="sleepSubs=" set "SLEEPSUB=%LINE:~10%"
if /i "%LINE:~0,7%"=="langPt=" set "LANGPT=%LINE:~7%"
if /i "%LINE:~0,7%"=="langEn=" set "LANGEN=%LINE:~7%"
if /i "%LINE:~0,7%"=="langJa=" set "LANGJA=%LINE:~7%"
if /i "%LINE:~0,12%"=="updateAsked=" set "UPDASK=%LINE:~12%"
exit /b

:salvar
>"%CFG%" echo # Configuracao do Baixador. Veja o README.txt
>>"%CFG%" echo defaultVideoFolder=%DFV%
>>"%CFG%" echo defaultMusicFolder=%DFM%
>>"%CFG%" echo threads=%THREADS%
>>"%CFG%" echo subsExe=%SUBEXE%
>>"%CFG%" echo sleepSubs=%SLEEPSUB%
>>"%CFG%" echo langPt=%LANGPT%
>>"%CFG%" echo langEn=%LANGEN%
>>"%CFG%" echo langJa=%LANGJA%
>>"%CFG%" echo updateAsked=%UPDASK%
exit /b

:contar
set "CNT=0"
for /f %%n in ('dir /b /s "%P%\*.srt" 2^>nul ^| find /c /v ""') do set "CNT=%%n"
exit /b