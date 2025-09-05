"""
Exemplo de teste que utiliza uma fixture parametrizada.
"""

import pytest


def test_user_permissions(user_account):
    """
    Testa as permissões de diferentes tipos de usuário.
    Este teste será executado duas vezes: uma para o usuário 'admin'
    e outra para o usuário 'guest', pois a fixture 'user_account' é parametrizada.
    """
    # A fixture 'user_account' fornecerá um dicionário de usuário diferente a cada execução.
    permissions = user_account["permissions"]
    user_type = user_account["type"]

    if user_type == "admin":
        assert "write" in permissions
        assert "delete" in permissions
    elif user_type == "guest":
        assert "write" not in permissions
        assert "delete" not in permissions
