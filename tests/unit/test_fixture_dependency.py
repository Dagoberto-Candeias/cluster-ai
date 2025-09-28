"""
Exemplo de teste que utiliza uma fixture dependente.
"""

import pytest


def test_read_from_temp_file(temp_file_with_content):
    """
    Testa a leitura de um arquivo criado pela fixture 'temp_file_with_content',
    que por sua vez depende da fixture 'temp_dir'.
    """
    # Arrange: A fixture nos fornece o caminho e o conteúdo esperado
    file_path, expected_content = temp_file_with_content

    # Act: Lemos o conteúdo do arquivo
    read_content = file_path.read_text(encoding="utf-8")

    # Assert: Verificamos se o conteúdo lido é o esperado
    assert read_content == expected_content
    assert file_path.exists()
