"""
Exemplo de teste que utiliza o padrão 'factory as a fixture'.
"""

import pytest


def test_interaction_between_users(user_account_factory):
    """
    Testa um cenário onde um admin pode realizar uma ação que um guest não pode.
    A factory permite criar ambos os usuários no mesmo teste.
    """
    # Arrange: Crie um usuário admin e um guest usando a factory
    admin_user = user_account_factory(user_type="admin")
    guest_user = user_account_factory(user_type="guest")

    # Act & Assert: Simule uma verificação de permissão
    def can_delete_files(user):
        return "delete" in user["permissions"]

    assert can_delete_files(admin_user) is True
    assert can_delete_files(guest_user) is False
