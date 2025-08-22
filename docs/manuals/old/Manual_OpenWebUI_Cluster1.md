# Manual de Instalação e Uso - Open WebUI + Ollama

## 📦 1. Pré-requisitos
- **Linux (Ubuntu recomendado)**
- **Python 3.13+**
- **Docker**
- **Ollama instalado no host**
- Acesso à internet

---

## ⚙️ 2. Instalação do Script
Baixe o script:

```bash
wget https://seu-servidor/open_webui_cluster.sh -O open_webui_cluster.sh
chmod +x open_webui_cluster.sh
./open_webui_cluster.sh
```

---

## 🖥️ 3. Menu Interativo
Ao rodar o script, você verá o menu:

```
1) Instalar dependências
2) Criar ambiente virtual
3) Ativar ambiente
4) Desativar ambiente
5) Instalar pacotes no ambiente
6) Iniciar Open WebUI
7) Parar Open WebUI
8) Ver status do Open WebUI
9) Testar envio de email
0) Sair
```

---

## 🧩 4. Gerenciamento do Ambiente
- Criar: opção **2**
- Ativar: opção **3**
- Desativar: opção **4**
- Instalar pacotes: opção **5**

---

## 🤖 5. Rodando o Open WebUI
1. Certifique-se de que o Ollama está rodando:
   ```bash
   ollama serve
   ```
2. Inicie o Open WebUI pelo menu (**opção 6**).
3. Acesse no navegador:
   👉 [http://localhost:8080](http://localhost:8080)

---

## 🔗 6. Integração com Ollama
O script detecta automaticamente:
- `http://host.docker.internal:11434`
- Caso não funcione, usa `http://172.17.0.1:11434`.

Verifique dentro do container:
```bash
docker exec -it open-webui env | grep OLLAMA
```

---

## 📧 7. Alertas por E-mail
1. Configure `~/.msmtprc`:
   ```
   defaults
   auth on
   tls on
   tls_trust_file /etc/ssl/certs/ca-certificates.crt
   logfile ~/.msmtp.log

   account gmail
   host smtp.gmail.com
   port 587
   from betoallnet@gmail.com
   user betoallnet@gmail.com
   password "SUA_SENHA_DE_APP"
   account default : gmail
   ```
   > Use **senha de app do Gmail**, não a senha normal.

2. Teste pelo menu (**opção 9**).

---

## 🛠️ 8. Troubleshooting
- **Erro `address already in use`**  
  → Outro processo Ollama já está rodando. Mate com:  
  ```bash
  sudo fuser -k 11434/tcp
  ```

- **Modelos não aparecem no WebUI**  
  → Verifique variável de ambiente:  
  ```bash
  docker exec -it open-webui env | grep OLLAMA
  ```

- **Erro ao enviar email**  
  → Confira se `~/.msmtprc` está com `chmod 600`.

---

## ✅ 9. Conclusão
Com esse script, você pode:
- Gerenciar o ambiente virtual.  
- Subir/parar o Open WebUI com integração ao Ollama.  
- Receber alertas automáticos por e-mail.  
