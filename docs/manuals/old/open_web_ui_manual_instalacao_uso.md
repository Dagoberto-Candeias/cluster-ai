# 📘 Manual de Instalação e Uso – Open WebUI com Alertas Automáticos

Este manual orienta a instalação e o uso do script `open_webui_auto_alert.sh`.

---

## 🔹 Pré-requisitos
- Ubuntu 20.04 ou superior (testado no 25.04 Plucky)
- Conexão com a internet
- Conta Gmail com **Senha de App** gerada  
  (Guia oficial: https://myaccount.google.com/apppasswords)

---

## 🔹 Instalação

1. **Baixar o script**
   ```bash
   wget https://SEU_LINK/open_webui_auto_alert.sh
   chmod +x open_webui_auto_alert.sh
   ```

2. **Executar o script**
   ```bash
   ./open_webui_auto_alert.sh
   ```

3. **Inserir a senha de app do Gmail** quando solicitado.

---

## 🔹 O que o script faz
1. Instala **Docker**, **Docker Compose**, **msmtp** e **mailutils**  
   (com suporte automático para Ubuntu moderno).
2. Configura o envio de e-mails via Gmail.
3. Testa o envio de um e-mail de confirmação.
4. Baixa e inicia o container **Open WebUI** na porta `8080`.
5. Cria um **cron job** que monitora o container a cada minuto e envia e-mail se ele cair.

---

## 🔹 Acessando o Open WebUI
- URL local: [http://localhost:8080](http://localhost:8080)  
- URL em rede: `http://IP_DA_MAQUINA:8080`

---

## 🔹 Logs
- Logs de envio de e-mail: `/var/log/msmtp.log`
- Logs do container:
  ```bash
  docker logs -f open-webui
  ```

---

## 🔹 Monitoramento
- A cada minuto o script de monitoramento verifica se o container `open-webui` está rodando.
- Caso não esteja, um **alerta por e-mail** é enviado para `betoallnet@gmail.com`.

---

## 🔹 Manutenção
- **Parar o container**  
  ```bash
  docker stop open-webui
  ```
- **Iniciar novamente**  
  ```bash
  docker start open-webui
  ```
- **Remover container**  
  ```bash
  docker rm -f open-webui
  ```

---

✅ **Pronto!** Agora seu Open WebUI roda com monitoramento automático e alertas via Gmail.
