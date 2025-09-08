#!/usr/bin/env python3
"""
Exemplo Prático: Chat com Modelos de IA no Cluster AI
====================================================

Este exemplo demonstra como usar modelos de linguagem avançados (Llama, Mistral, etc.)
através do Ollama no Cluster AI para tarefas de conversação inteligente.

Pré-requisitos:
- Cluster AI instalado e rodando
- Pelo menos um modelo baixado (ex: llama3:8b, mistral:7b)

Uso:
    python chat_example.py [--model nome_do_modelo] [--interactive]
"""

import argparse
import json
import time
from typing import List, Dict, Any
from ollama import Client
from dask.distributed import Client as DaskClient


class AIChatAssistant:
    """Assistente de chat inteligente usando modelos Ollama."""

    def __init__(self, model_name: str = "llama3:8b", host: str = "http://localhost:11434"):
        self.model_name = model_name
        self.client = Client(host=host)
        self.conversation_history: List[Dict[str, str]] = []

        # Verificar se o modelo está disponível
        self._check_model_availability()

    def _check_model_availability(self):
        """Verifica se o modelo está disponível localmente."""
        try:
            models = self.client.list()
            print(f"🔍 Resposta da API: {models}")  # Debug

            # Verificar estrutura da resposta
            if 'models' not in models:
                print("⚠️  Estrutura de resposta inesperada da API Ollama")
                print(f"📋 Resposta completa: {models}")
                # Tentar usar modelo diretamente sem verificação
                print(f"🔄 Tentando usar modelo '{self.model_name}' sem verificação...")
                return

            available_models = []
            for model in models['models']:
                # Model objects têm atributo 'model' com o nome
                if hasattr(model, 'model'):
                    model_name = model.model
                elif isinstance(model, dict):
                    model_name = model.get('name') or model.get('model') or str(model)
                else:
                    model_name = str(model)
                available_models.append(model_name)

            print(f"📋 Modelos encontrados: {available_models}")

            if self.model_name not in available_models:
                print(f"⚠️  Modelo '{self.model_name}' não encontrado localmente.")
                print(f"📋 Modelos disponíveis: {', '.join(available_models[:5])}")
                if available_models:
                    self.model_name = available_models[0]
                    print(f"🔄 Usando modelo alternativo: {self.model_name}")
                else:
                    raise ValueError("Nenhum modelo encontrado. Execute: ollama pull llama3:8b")
            else:
                print(f"✅ Modelo '{self.model_name}' carregado com sucesso!")

        except Exception as e:
            print(f"❌ Erro ao verificar modelos: {e}")
            print("🔄 Continuando sem verificação de modelos...")
            # Não lançar erro, permitir que o usuário tente usar o modelo

    def chat(self, message: str, system_prompt: str | None = None) -> str:
        """Envia uma mensagem para o modelo e retorna a resposta."""
        # Preparar mensagens
        messages = []

        # Adicionar prompt do sistema se fornecido
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})

        # Adicionar histórico da conversa
        messages.extend(self.conversation_history)

        # Adicionar mensagem atual
        messages.append({"role": "user", "content": message})

        try:
            start_time = time.time()

            # Fazer a chamada para o modelo
            response = self.client.chat(
                model=self.model_name,
                messages=messages,
                options={
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "num_predict": 1024
                }
            )

            response_time = time.time() - start_time
            ai_response = response['message']['content']

            # Adicionar ao histórico
            self.conversation_history.append({"role": "user", "content": message})
            self.conversation_history.append({"role": "assistant", "content": ai_response})

            # Manter histórico limitado
            if len(self.conversation_history) > 20:
                self.conversation_history = self.conversation_history[-20:]

            print(".2f")
            return ai_response

        except Exception as e:
            error_msg = f"Erro na comunicação com o modelo: {e}"
            print(f"❌ {error_msg}")
            return error_msg

    def analyze_text(self, text: str, task: str) -> Dict[str, Any]:
        """Análise avançada de texto usando o modelo."""
        system_prompt = f"""Você é um assistente especializado em {task}.
        Forneça uma análise detalhada e estruturada do texto fornecido.
        Organize sua resposta em seções claras com headers descritivos."""

        prompt = f"""
        Texto para análise:
        ---
        {text}
        ---

        Tarefa: {task}

        Por favor, forneça:
        1. Resumo executivo
        2. Análise detalhada
        3. Insights principais
        4. Recomendações (se aplicável)
        """

        response = self.chat(prompt, system_prompt)

        return {
            "task": task,
            "text_length": len(text),
            "analysis": response,
            "model_used": self.model_name,
            "timestamp": time.time()
        }

    def generate_code(self, requirement: str, language: str = "python") -> str:
        """Gera código baseado em requisitos."""
        system_prompt = f"""Você é um programador especialista em {language}.
        Forneça código limpo, bem documentado e seguindo as melhores práticas."""

        prompt = f"""
        Gere código {language} para o seguinte requisito:

        {requirement}

        Inclua:
        - Comentários explicativos
        - Tratamento de erros
        - Exemplos de uso
        - Documentação das funções
        """

        return self.chat(prompt, system_prompt)

    def translate_text(self, text: str, target_language: str, source_language: str = "auto") -> str:
        """Traduz texto para outro idioma."""
        system_prompt = "Você é um tradutor profissional. Forneça traduções precisas e naturais."

        if source_language == "auto":
            source_language = "português"

        prompt = f"""
        Traduza o seguinte texto do {source_language} para {target_language}:

        Texto original:
        {text}

        Forneça apenas a tradução, sem explicações adicionais.
        """

        return self.chat(prompt, system_prompt)

    def clear_history(self):
        """Limpa o histórico da conversa."""
        self.conversation_history.clear()
        print("🧹 Histórico da conversa limpo!")

    def get_conversation_stats(self) -> Dict[str, Any]:
        """Retorna estatísticas da conversa atual."""
        user_messages = len([msg for msg in self.conversation_history if msg['role'] == 'user'])
        assistant_messages = len([msg for msg in self.conversation_history if msg['role'] == 'assistant'])

        total_chars = sum(len(msg['content']) for msg in self.conversation_history)

        return {
            "total_messages": len(self.conversation_history),
            "user_messages": user_messages,
            "assistant_messages": assistant_messages,
            "total_characters": total_chars,
            "model": self.model_name
        }


def interactive_chat(assistant: AIChatAssistant):
    """Interface de chat interativo."""
    print("🤖 Chat Interativo com Cluster AI")
    print("=" * 50)
    print(f"📚 Modelo: {assistant.model_name}")
    print("💡 Comandos especiais:")
    print("  /clear - Limpar histórico")
    print("  /stats - Ver estatísticas")
    print("  /analyze [tarefa] - Análise de texto")
    print("  /code [linguagem] - Gerar código")
    print("  /translate [idioma] - Traduzir texto")
    print("  /quit - Sair")
    print("=" * 50)

    while True:
        try:
            user_input = input("\n👤 Você: ").strip()

            if not user_input:
                continue

            if user_input.lower() in ['/quit', 'quit', 'sair', 'exit']:
                print("👋 Até logo!")
                break

            elif user_input.lower() == '/clear':
                assistant.clear_history()

            elif user_input.lower() == '/stats':
                stats = assistant.get_conversation_stats()
                print("\n📊 Estatísticas da Conversa:")
                print(f"   • Total de mensagens: {stats['total_messages']}")
                print(f"   • Suas mensagens: {stats['user_messages']}")
                print(f"   • Respostas do AI: {stats['assistant_messages']}")
                print(f"   • Total de caracteres: {stats['total_characters']:,}")

            elif user_input.lower().startswith('/analyze '):
                task = user_input[9:].strip()
                if not task:
                    print("❌ Especifique a tarefa. Exemplo: /analyze resumir texto")
                    continue

                text = input("📄 Texto para analisar: ").strip()
                if not text:
                    print("❌ Texto não pode estar vazio.")
                    continue

                print("\n🔍 Analisando...")
                result = assistant.analyze_text(text, task)
                print(f"\n📋 Análise ({task}):")
                print(result['analysis'])

            elif user_input.lower().startswith('/code '):
                lang = user_input[6:].strip() or "python"
                requirement = input(f"📝 Requisito para código {lang}: ").strip()
                if not requirement:
                    print("❌ Requisito não pode estar vazio.")
                    continue

                print(f"\n💻 Gerando código {lang}...")
                code = assistant.generate_code(requirement, lang)
                print(f"\n``` {lang}")
                print(code)
                print("```")

            elif user_input.lower().startswith('/translate '):
                target_lang = user_input[11:].strip()
                if not target_lang:
                    print("❌ Especifique o idioma. Exemplo: /translate inglês")
                    continue

                text = input("📄 Texto para traduzir: ").strip()
                if not text:
                    print("❌ Texto não pode estar vazio.")
                    continue

                print(f"\n🌍 Traduzindo para {target_lang}...")
                translation = assistant.translate_text(text, target_lang)
                print(f"\n📋 Tradução ({target_lang}):")
                print(translation)

            else:
                # Chat normal
                print("\n🤖 AI:")
                response = assistant.chat(user_input)
                print(response)

        except KeyboardInterrupt:
            print("\n👋 Chat interrompido pelo usuário!")
            break
        except Exception as e:
            print(f"❌ Erro: {e}")


def demo_examples(assistant: AIChatAssistant):
    """Demonstra vários recursos do assistente."""
    print("🚀 Demonstração dos Recursos do Cluster AI")
    print("=" * 60)

    # Exemplo 1: Chat simples
    print("\n1️⃣ Chat Simples:")
    response = assistant.chat("Olá! Explique o que é machine learning em uma frase.")
    print(f"🤖 {response}")

    # Exemplo 2: Análise de texto
    print("\n2️⃣ Análise de Sentimentos:")
    text = "Este produto é incrível! Funciona perfeitamente e superou minhas expectativas."
    analysis = assistant.analyze_text(text, "análise de sentimentos")
    print(f"📄 Texto: {text}")
    print(f"🔍 Análise: {analysis['analysis'][:200]}...")

    # Exemplo 3: Geração de código
    print("\n3️⃣ Geração de Código:")
    code = assistant.generate_code("Criar uma função que calcula a média de uma lista de números", "python")
    print("```python")
    print(code[:300] + "..." if len(code) > 300 else code)
    print("```")

    # Exemplo 4: Tradução
    print("\n4️⃣ Tradução:")
    translation = assistant.translate_text("Hello, how are you?", "português")
    print(f"🇺🇸 Hello, how are you? → 🇧🇷 {translation}")

    # Estatísticas finais
    print("\n📊 Estatísticas da Demonstração:")
    stats = assistant.get_conversation_stats()
    for key, value in stats.items():
        print(f"   • {key}: {value}")


def main():
    parser = argparse.ArgumentParser(description='Chat com IA no Cluster AI')
    parser.add_argument('--model', '-m', default='llama3:8b',
                       help='Nome do modelo Ollama (padrão: llama3:8b)')
    parser.add_argument('--interactive', '-i', action='store_true',
                       help='Modo interativo de chat')
    parser.add_argument('--demo', '-d', action='store_true',
                       help='Executar demonstração dos recursos')
    parser.add_argument('--host', default='http://localhost:11434',
                       help='Host do servidor Ollama')

    args = parser.parse_args()

    print("🚀 Cluster AI - Chat com IA")
    print("=" * 40)

    try:
        # Inicializar assistente
        assistant = AIChatAssistant(args.model, args.host)

        if args.demo:
            # Executar demonstração
            demo_examples(assistant)
        elif args.interactive:
            # Modo interativo
            interactive_chat(assistant)
        else:
            # Chat simples
            print("💡 Modo simples - Digite sua mensagem:")
            while True:
                try:
                    message = input("\n👤 Você: ").strip()
                    if message.lower() in ['quit', 'sair', 'exit']:
                        break
                    if message:
                        response = assistant.chat(message)
                        print(f"\n🤖 AI: {response}")
                except KeyboardInterrupt:
                    break

        print("\n✅ Sessão finalizada!")

    except Exception as e:
        print(f"❌ Erro: {e}")
        print("\n💡 Dicas para solução:")
        print("   • Verifique se o Cluster AI está rodando: ./manager.sh")
        print("   • Baixe um modelo: ollama pull llama3:8b")
        print("   • Verifique a conexão: curl http://localhost:11434/api/tags")


if __name__ == "__main__":
    main()
