import os
import json
import uuid
from typing import Dict, List, Any
from django.contrib.auth.models import User
from .models import (
    Profile, UserTier, Tier, Achievement, UserAchievement, 
    Reward, UserReward, Friendship, AIConversation, AIMessage
)

class AIGamificationService:
    """Serviço de IA para gamificação e recomendações"""
    
    def __init__(self):
        self.openai_key = os.getenv("OPENAI_API_KEY")
    
    def get_user_gamification_context(self, user: User) -> Dict[str, Any]:
        """Obtém contexto completo de gamificação do usuário"""
        try:
            profile = Profile.objects.get(user=user)
            user_tier = UserTier.objects.get(user=user)
            
            # Estatísticas de referrals
            total_referrals = Friendship.objects.filter(user=user, is_referred=True).count()
            successful_referrals = total_referrals  # Todos são considerados bem-sucedidos
            
            # Conquistas
            user_achievements = UserAchievement.objects.filter(user=user)
            achievements_count = user_achievements.count()
            
            # Recompensas
            available_rewards = Reward.objects.filter(is_active=True)
            user_rewards = UserReward.objects.filter(user=user)
            claimed_rewards = user_rewards.count()
            
            # Próximo tier
            next_tier = Tier.objects.filter(
                min_referrals__gt=user_tier.current_referrals
            ).order_by('min_referrals').first()
            
            referrals_to_next = 0
            if next_tier:
                referrals_to_next = next_tier.min_referrals - user_tier.current_referrals
            
            return {
                'username': user.username,
                'current_tier': user_tier.tier.name,
                'current_referrals': user_tier.current_referrals,
                'total_points': user_tier.total_points,
                'next_tier': next_tier.name if next_tier else None,
                'referrals_to_next': referrals_to_next,
                'achievements_count': achievements_count,
                'claimed_rewards': claimed_rewards,
                'available_rewards_count': available_rewards.count(),
                'total_referrals': total_referrals,
                'successful_referrals': successful_referrals,
            }
        except Exception as e:
            return {'error': str(e)}
    
    def generate_ai_response(self, user: User, user_message: str) -> str:
        """Gera resposta da IA baseada no contexto do usuário"""
        context = self.get_user_gamification_context(user)
        
        if 'error' in context:
            return "Desculpe, não consegui acessar suas informações no momento. Tente novamente mais tarde."
        
        # Prompt baseado no contexto
        prompt = self._build_prompt(context, user_message)
        
        # Se não há chave da OpenAI, usar respostas pré-definidas
        if not self.openai_key:
            return self._get_fallback_response(context, user_message)
        
        try:
            import openai
            openai.api_key = self.openai_key
            
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": self._get_system_prompt()},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=500,
                temperature=0.7
            )
            
            return response.choices[0].message.content.strip()
        except Exception as e:
            return self._get_fallback_response(context, user_message)
    
    def _build_prompt(self, context: Dict[str, Any], user_message: str) -> str:
        """Constrói prompt para a IA"""
        return f"""
Contexto do usuário:
- Nome: {context['username']}
- Tier atual: {context['current_tier']}
- Referrals: {context['current_referrals']}
- Pontos: {context['total_points']}
- Próximo tier: {context['next_tier'] or 'Máximo alcançado'}
- Referrals para próximo tier: {context['referrals_to_next']}
- Conquistas: {context['achievements_count']}
- Recompensas resgatadas: {context['claimed_rewards']}
- Recompensas disponíveis: {context['available_rewards_count']}

Mensagem do usuário: {user_message}

Responda de forma amigável e útil, dando conselhos específicos sobre como melhorar o tier, usar pontos e ganhar mais referrals.
"""
    
    def _get_system_prompt(self) -> str:
        """Prompt do sistema para a IA"""
        return """
Você é um assistente de gamificação especializado em ajudar usuários a maximizar seus pontos e progredir nos tiers do Forkly.

Seu papel é:
1. Analisar a situação atual do usuário
2. Dar conselhos específicos sobre como ganhar mais referrals
3. Sugerir como usar pontos de forma estratégica
4. Motivar o usuário a continuar progredindo
5. Explicar benefícios dos tiers

Seja sempre positivo, motivador e prático. Use emojis ocasionalmente para tornar a conversa mais amigável.
"""
    
    def _get_fallback_response(self, context: Dict[str, Any], user_message: str) -> str:
        """Resposta de fallback quando OpenAI não está disponível"""
        tier = context['current_tier']
        referrals = context['current_referrals']
        points = context['total_points']
        next_tier = context['next_tier']
        referrals_to_next = context['referrals_to_next']
        
        # Respostas baseadas em palavras-chave
        message_lower = user_message.lower()
        
        if any(word in message_lower for word in ['tier', 'nível', 'progresso']):
            if next_tier:
                return f"""🎯 **Seu Progresso no Tier {tier}**

Você está no tier **{tier}** com {referrals} referrals e {points} pontos!

Para chegar ao próximo tier **{next_tier}**, você precisa de mais **{referrals_to_next} referrals**.

💡 **Dicas para ganhar mais referrals:**
• Compartilhe seu código de referência nas redes sociais
• Convide amigos pessoalmente
• Participe de grupos sobre comida e restaurantes
• Seja ativo na comunidade Forkly

Continue assim! 🚀"""
            else:
                return f"""🏆 **Parabéns! Você alcançou o tier máximo!**

Você está no tier **{tier}** - o mais alto possível! 

Com {referrals} referrals e {points} pontos, você é um verdadeiro embaixador do Forkly! 

💎 **Continue compartilhando e ajudando outros usuários a descobrirem os melhores restaurantes!**"""
        
        elif any(word in message_lower for word in ['pontos', 'points', 'recompensa']):
            return f"""💰 **Seus Pontos: {points}**

Com {points} pontos, você pode:

🎁 **Resgatar recompensas disponíveis**
• Descontos em restaurantes
• Itens grátis
• Recursos premium

💡 **Como ganhar mais pontos:**
• Cada referral = +50 pontos
• Primeira review de referral = +100 pontos
• Complete conquistas para pontos extras

🔍 **Dica:** Verifique a aba "Recompensas" para ver o que você pode resgatar agora!"""
        
        elif any(word in message_lower for word in ['referral', 'indicar', 'convidar']):
            return f"""👥 **Seus Referrals: {referrals}**

Para ganhar mais referrals:

📱 **Estratégias eficazes:**
• Compartilhe seu código em grupos de WhatsApp sobre comida
• Poste nas redes sociais com hashtags #Forkly #Restaurantes
• Convide amigos pessoalmente
• Participe de eventos gastronômicos

🎯 **Meta:** {referrals_to_next} referrals para o próximo tier!

💪 **Você consegue! Cada referral conta!**"""
        
        else:
            return f"""👋 **Olá! Sou seu assistente de gamificação!**

Vejo que você está no tier **{tier}** com {referrals} referrals e {points} pontos!

Como posso te ajudar hoje? Posso te dar dicas sobre:
• 🎯 Como progredir para o próximo tier
• 💰 Como usar seus pontos
• 👥 Como ganhar mais referrals
• 🏆 Como desbloquear conquistas

O que você gostaria de saber? 😊"""
    
    def create_conversation(self, user: User) -> AIConversation:
        """Cria uma nova conversa com IA"""
        session_id = str(uuid.uuid4())
        conversation = AIConversation.objects.create(
            user=user,
            session_id=session_id
        )
        return conversation
    
    def add_message(self, conversation: AIConversation, role: str, content: str, 
                   message_type: str = 'text', metadata: Dict = None) -> AIMessage:
        """Adiciona mensagem à conversa"""
        return AIMessage.objects.create(
            conversation=conversation,
            role=role,
            content=content,
            message_type=message_type,
            metadata=metadata or {}
        )
    
    def get_conversation_history(self, conversation: AIConversation) -> List[Dict]:
        """Obtém histórico da conversa"""
        messages = conversation.messages.all()
        return [
            {
                'role': msg.role,
                'content': msg.content,
                'message_type': msg.message_type,
                'created_at': msg.created_at.isoformat(),
                'metadata': msg.metadata
            }
            for msg in messages
        ]
