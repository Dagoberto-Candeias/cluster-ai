#!/usr/bin/env python3
"""
Exemplo Prático: Processamento Distribuído de Imagens com Cluster AI
=================================================================

Este exemplo demonstra como processar milhares de imagens em paralelo usando
Dask e Cluster AI, aplicando filtros, redimensionamento e análise de conteúdo.

Pré-requisitos:
- Cluster AI instalado e rodando
- Bibliotecas: pillow, numpy, dask, matplotlib
- Diretório com imagens para processamento

Uso:
    python image_processing.py [--input dir_imagens] [--output dir_saida] [--batch-size 100]
"""

import argparse
import os
import time
from pathlib import Path
from typing import List, Tuple, Dict, Any, Optional
import numpy as np
from PIL import Image, ImageFilter, ImageEnhance
import dask
import dask.bag as db
from dask.distributed import Client, LocalCluster
import matplotlib.pyplot as plt


class DistributedImageProcessor:
    """Processador distribuído de imagens usando Dask."""

    def __init__(self, cluster_client=None):
        self.client = cluster_client
        self.processed_count = 0
        self.errors_count = 0

    def find_images(
        self, input_dir: str, extensions: Optional[List[str]] = None
    ) -> List[str]:
        """Encontra todas as imagens no diretório especificado."""
        if extensions is None:
            extensions = [".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".webp"]

        image_paths = []
        input_path = Path(input_dir)

        if not input_path.exists():
            raise FileNotFoundError(f"Diretorio nao encontrado: {input_dir}")

        for ext in extensions:
            image_paths.extend(input_path.rglob(f"*{ext}"))
            image_paths.extend(input_path.rglob(f"*{ext.upper()}"))

        print(f"📁 Encontradas {len(image_paths)} imagens em {input_dir}")
        return [str(path) for path in image_paths]

    def load_image(self, image_path: str) -> Tuple[str, Optional[np.ndarray]]:
        """Carrega uma imagem e converte para array numpy."""
        try:
            with Image.open(image_path) as img:
                # Converter para RGB se necessario
                if img.mode != "RGB":
                    img = img.convert("RGB")

                # Converter para array numpy
                img_array = np.array(img)

                return image_path, img_array

        except Exception as e:
            print(f"❌ Erro ao carregar {image_path}: {e}")
            return image_path, None

    def apply_filters(
        self, image_data: Tuple[str, Optional[np.ndarray]]
    ) -> Tuple[str, Dict[str, Any]]:
        """Aplica varios filtros e processamentos a imagem."""
        image_path, img_array = image_data

        if img_array is None:
            return image_path, {"error": "Falha no carregamento"}

        try:
            # Converter de volta para PIL Image para processamento
            img = Image.fromarray(img_array)

            results = {
                "original_size": img.size,
                "original_mode": img.mode,
                "filters": {},
            }

            # 1. Filtro de nitidez
            sharpened = img.filter(
                ImageFilter.UnsharpMask(radius=1, percent=150, threshold=3)
            )
            results["filters"]["sharpened"] = np.array(sharpened)

            # 2. Correcao de brilho
            enhancer = ImageEnhance.Brightness(img)
            brightened = enhancer.enhance(1.2)
            results["filters"]["brightened"] = np.array(brightened)

            # 3. Aumento de contraste
            enhancer = ImageEnhance.Contrast(img)
            contrasted = enhancer.enhance(1.3)
            results["filters"]["contrasted"] = np.array(contrasted)

            # 4. Desfoque gaussiano
            blurred = img.filter(ImageFilter.GaussianBlur(radius=2))
            results["filters"]["blurred"] = np.array(blurred)

            # 5. Deteccao de bordas
            edges = img.filter(ImageFilter.FIND_EDGES)
            results["filters"]["edges"] = np.array(edges)

            # 6. Estatisticas da imagem
            img_gray = img.convert("L")
            img_array_gray = np.array(img_gray)

            results["statistics"] = {
                "mean_intensity": float(img_array_gray.mean()),
                "std_intensity": float(img_array_gray.std()),
                "min_intensity": int(img_array_gray.min()),
                "max_intensity": int(img_array_gray.max()),
                "median_intensity": int(np.median(img_array_gray)),
            }

            # 7. Redimensionamento
            resized = img.resize((224, 224), Image.Resampling.LANCZOS)
            results["resized_224"] = np.array(resized)

            resized_small = img.resize((64, 64), Image.Resampling.LANCZOS)
            results["resized_64"] = np.array(resized_small)

            return image_path, results

        except Exception as e:
            print(f"❌ Erro ao processar {image_path}: {e}")
            return image_path, {"error": str(e)}

    def save_processed_image(
        self, result: Tuple[str, Dict[str, Any]], output_dir: str
    ) -> str:
        """Salva as imagens processadas."""
        image_path, processed_data = result

        if "error" in processed_data:
            self.errors_count += 1
            return f"Erro em {image_path}: {processed_data['error']}"

        try:
            # Criar diretorio de saida
            output_path = Path(output_dir)
            output_path.mkdir(parents=True, exist_ok=True)

            # Nome base do arquivo
            base_name = Path(image_path).stem
            ext = Path(image_path).suffix

            saved_files = []

            # Salvar versoes processadas
            for filter_name, img_array in processed_data.get("filters", {}).items():
                if isinstance(img_array, np.ndarray):
                    img = Image.fromarray(img_array)
                    output_file = output_path / f"{base_name}_{filter_name}{ext}"
                    img.save(output_file, quality=90)
                    saved_files.append(str(output_file))

            # Salvar versoes redimensionadas
            for size_name, img_array in processed_data.items():
                if size_name.startswith("resized_") and isinstance(
                    img_array, np.ndarray
                ):
                    img = Image.fromarray(img_array)
                    size = size_name.split("_")[1]
                    output_file = output_path / f"{base_name}_{size}x{size}{ext}"
                    img.save(output_file, quality=90)
                    saved_files.append(str(output_file))

            self.processed_count += 1

            return f"Processada: {image_path} -> {len(saved_files)} arquivos salvos"

        except Exception as e:
            self.errors_count += 1
            return f"Erro ao salvar {image_path}: {e}"

    def create_summary_report(
        self, results: List[str], output_dir: str
    ) -> Dict[str, Any]:
        """Cria um relatorio resumido do processamento."""
        successful = len([r for r in results if r.startswith("Processada:")])
        errors = len([r for r in results if r.startswith("Erro")])

        report = {
            "total_images": len(results),
            "successful": successful,
            "errors": errors,
            "success_rate": successful / len(results) * 100 if results else 0,
            "output_directory": output_dir,
            "timestamp": time.time(),
        }

        # Salvar relatorio
        report_path = Path(output_dir) / "processing_report.json"
        with open(report_path, "w", encoding="utf-8") as f:
            import json

            json.dump(report, f, indent=2, ensure_ascii=False, default=str)

        return report


def process_images_distributed(
    input_dir: str, output_dir: str, batch_size: int = 50
) -> Dict[str, Any]:
    """Processa imagens de forma distribuida usando Dask."""
    print("🚀 Iniciando processamento distribuido de imagens")
    print("=" * 60)

    # Conectar ao cluster
    try:
        client = Client("tcp://localhost:8786")
        print("🔗 Conectado ao cluster Dask existente")
    except:
        print("🏠 Iniciando cluster local...")
        cluster = LocalCluster(
            n_workers=4,
            threads_per_worker=2,
            memory_limit="2GB",
            dashboard_address=":8788",
        )
        client = Client(cluster)

    print(f"👷 Workers disponiveis: {len(client.scheduler_info()['workers'])}")

    try:
        # Inicializar processador
        processor = DistributedImageProcessor(client)

        # Encontrar imagens
        image_paths = processor.find_images(input_dir)

        if not image_paths:
            print("❌ Nenhuma imagem encontrada!")
            return {"error": "no_images_found"}

        # Criar output directory
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        # Processamento em lotes para melhor controle de memoria
        all_results = []
        start_time = time.time()

        for i in range(0, len(image_paths), batch_size):
            batch = image_paths[i : i + batch_size]
            print(
                f"\n🔄 Processando lote {i//batch_size + 1}/{(len(image_paths) + batch_size - 1)//batch_size}"
            )
            print(f"   Imagens: {len(batch)}")

            # Criar bag do Dask para processamento distribuido
            image_bag = db.from_sequence(batch, partition_size=10)

            # Pipeline de processamento
            results = (
                image_bag.map(processor.load_image)
                .map(processor.apply_filters)
                .map(lambda x: processor.save_processed_image(x, output_dir))
                .compute()
            )

            all_results.extend(results)

            # Progress report
            processed = len([r for r in results if r.startswith("Processada:")])
            errors = len([r for r in results if r.startswith("Erro")])
            print(f"   Sucesso: {processed} | Erros: {errors}")

        # Tempo total
        total_time = time.time() - start_time

        # Criar relatorios
        print("\n📊 Gerando relatorios...")
        summary = processor.create_summary_report(all_results, output_dir)

        # Resultado final
        print("\n🎉 Processamento concluido!")
        print("=" * 60)
        print(f"⏱️  Tempo total: {total_time:.2f} segundos")
        print(
            f"📁 Imagens processadas: {summary['successful']}/{summary['total_images']}"
        )
        print(f"📊 Taxa de sucesso: {summary['success_rate']:.1f}%")
        print(f"💾 Resultados salvos em: {output_dir}")
        print(f"🌐 Dashboard: http://localhost:8787")

        return {
            "success": True,
            "total_images": summary["total_images"],
            "successful": summary["successful"],
            "errors": summary["errors"],
            "processing_time": total_time,
            "output_directory": output_dir,
        }

    except Exception as e:
        print(f"❌ Erro durante processamento: {e}")
        return {"error": str(e)}

    finally:
        client.close()


def create_demo_images(output_dir: str, num_images: int = 10):
    """Cria imagens de demonstracao para teste."""
    print(f"🎨 Criando {num_images} imagens de demonstracao...")

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    for i in range(num_images):
        # Criar imagem colorida aleatoria
        width, height = 800, 600
        img_array = np.random.randint(0, 255, (height, width, 3), dtype=np.uint8)

        # Adicionar alguns padroes
        # Circulos
        center_x, center_y = width // 2, height // 2
        y, x = np.ogrid[:height, :width]
        mask = (x - center_x) ** 2 + (y - center_y) ** 2 <= (
            min(width, height) // 4
        ) ** 2
        img_array[mask] = [255, 0, 0]  # Vermelho

        # Retangulos
        img_array[50:150, 50:150] = [0, 255, 0]  # Verde
        img_array[height - 150 : height - 50, width - 150 : width - 50] = [
            0,
            0,
            255,
        ]  # Azul

        # Salvar imagem
        img = Image.fromarray(img_array)
        img.save(output_path / "03d")

    print(f"✅ Imagens de demonstracao criadas em {output_dir}")


def main():
    parser = argparse.ArgumentParser(
        description="Processamento Distribuido de Imagens com Cluster AI"
    )
    parser.add_argument(
        "--input",
        "-i",
        default="./imagens_entrada",
        help="Diretorio com imagens de entrada",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="./imagens_processadas",
        help="Diretorio para salvar imagens processadas",
    )
    parser.add_argument(
        "--batch-size",
        "-b",
        type=int,
        default=50,
        help="Tamanho do lote para processamento",
    )
    parser.add_argument(
        "--create-demo",
        "-d",
        type=int,
        nargs="?",
        const=10,
        help="Criar imagens de demonstracao (opcional: numero de imagens)",
    )

    args = parser.parse_args()

    print("🚀 Cluster AI - Processamento Distribuido de Imagens")
    print("=" * 60)

    # Criar imagens de demonstracao se solicitado
    if args.create_demo:
        demo_dir = args.input
        create_demo_images(demo_dir, args.create_demo)

    # Verificar se diretorio de entrada existe
    if not Path(args.input).exists():
        print(f"❌ Diretorio de entrada nao encontrado: {args.input}")
        print("💡 Use --create-demo para criar imagens de teste")
        return

    # Processar imagens
    result = process_images_distributed(args.input, args.output, args.batch_size)

    if "error" in result:
        print(f"❌ Falha no processamento: {result['error']}")
    else:
        print("\n✅ Processamento finalizado com sucesso!")
        print(
            f"📊 Resumo: {result['successful']}/{result['total_images']} imagens processadas"
        )


if __name__ == "__main__":
    main()
