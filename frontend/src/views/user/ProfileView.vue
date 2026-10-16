<template>
  <AppLayout>
    <div
      data-testid="profile-shell"
      class="mx-auto max-w-[950px] space-y-6"
    >
      <ProfileInfoCard
        :user="user"
        :linuxdo-enabled="linuxdoOAuthEnabled"
        :dingtalk-enabled="dingtalkOAuthEnabled"
        :oidc-enabled="oidcOAuthEnabled"
        :oidc-provider-name="oidcOAuthProviderName"
        :wechat-enabled="wechatOAuthEnabled"
        :wechat-open-enabled="wechatOAuthOpenEnabled"
        :wechat-mp-enabled="wechatOAuthMPEnabled"
      />

      <div
        v-if="contactInfo"
        class="card border-primary-200 bg-primary-50 p-6 dark:bg-primary-900/20"
      >
        <div class="flex items-center gap-4">
          <div class="rounded-xl bg-primary-100 p-3 text-primary-600">
            <Icon name="chat" size="lg" />
          </div>
          <div>
            <h3 class="font-semibold text-primary-800 dark:text-primary-200">
              {{ t('common.contactSupport') }}
            </h3>
            <p class="text-sm font-medium">{{ contactInfo }}</p>
          </div>
        </div>
      </div>

      <ProfilePasswordForm />

      <ProfileBalanceNotifyCard
        v-if="user && balanceLowNotifyEnabled"
        :enabled="user.balance_notify_enabled ?? true"
        :threshold="user.balance_notify_threshold"
        :extra-emails="user.balance_notify_extra_emails ?? []"
        :system-default-threshold="systemDefaultThreshold"
        :user-email="user.email"
      />

      <section class="card space-y-4 p-6">
        <div>
          <h2 class="text-lg font-semibold">{{ t('user.balanceQuery.title') }}</h2>
          <p class="mt-1 text-sm text-gray-500">{{ t('user.balanceQuery.description') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <span class="text-sm">{{ keyEnabled ? t('user.balanceQuery.enabled') : t('user.balanceQuery.disabled') }}</span>
          <button class="btn btn-primary" :disabled="keyBusy" @click="createQueryKey">
            {{ keyEnabled ? t('user.balanceQuery.rotate') : t('user.balanceQuery.create') }}
          </button>
          <button v-if="keyEnabled" class="btn btn-secondary" :disabled="keyBusy" @click="revokeQueryKey">
            {{ t('user.balanceQuery.revoke') }}
          </button>
        </div>
        <div v-if="freshQueryKey" class="space-y-2 rounded-lg bg-gray-50 p-3 dark:bg-gray-800">
          <p class="break-all font-mono text-sm">{{ freshQueryKey }}</p>
          <p class="text-xs text-amber-600">{{ t('user.balanceQuery.oneTimeNotice') }}</p>
          <button class="btn btn-secondary" @click="copyQueryKey">{{ t('common.copy') }}</button>
        </div>
        <p class="break-all text-xs text-gray-500">GET {{ queryEndpoint }} (Authorization: Bearer &lt;key&gt;)</p>
        <p class="text-xs text-gray-500">{{ t('user.balanceQuery.usageParameters') }}</p>
      </section>

      <ProfileTotpCard />
      <ProfilePasskeyCard :enabled="passkeyEnabled" />
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { Icon } from '@/components/icons'
import AppLayout from '@/components/layout/AppLayout.vue'
import ProfileBalanceNotifyCard from '@/components/user/profile/ProfileBalanceNotifyCard.vue'
import ProfileInfoCard from '@/components/user/profile/ProfileInfoCard.vue'
import ProfilePasswordForm from '@/components/user/profile/ProfilePasswordForm.vue'
import ProfileTotpCard from '@/components/user/profile/ProfileTotpCard.vue'
import ProfilePasskeyCard from '@/components/user/profile/ProfilePasskeyCard.vue'
import { createBalanceQueryKey, getBalanceQueryKeyStatus, revokeBalanceQueryKey } from '@/api/user'
import { isWeChatWebOAuthEnabled } from '@/api/auth'
import { useAppStore } from '@/stores/app'
import { useAuthStore } from '@/stores/auth'

const { t } = useI18n()
const appStore = useAppStore()
const authStore = useAuthStore()
const user = computed(() => authStore.user)

const contactInfo = ref('')
const balanceLowNotifyEnabled = ref(false)
const systemDefaultThreshold = ref(0)
const linuxdoOAuthEnabled = ref(false)
const dingtalkOAuthEnabled = ref(false)
const wechatOAuthEnabled = ref(false)
const wechatOAuthOpenEnabled = ref<boolean | undefined>(undefined)
const wechatOAuthMPEnabled = ref<boolean | undefined>(undefined)
const oidcOAuthEnabled = ref(false)
const oidcOAuthProviderName = ref('OIDC')
const passkeyEnabled = ref(false)
const keyEnabled = ref(false)
const keyBusy = ref(false)
const freshQueryKey = ref('')
const queryEndpoint = `${window.location.origin}/api/v1/balance`

async function refreshQueryKeyStatus() {
  try { keyEnabled.value = (await getBalanceQueryKeyStatus()).enabled } catch (error) { console.error('Failed to load balance query key status:', error) }
}

async function createQueryKey() {
  keyBusy.value = true
  try {
    freshQueryKey.value = (await createBalanceQueryKey()).key
    keyEnabled.value = true
  } catch (error) { console.error('Failed to create balance query key:', error) } finally { keyBusy.value = false }
}

async function revokeQueryKey() {
  keyBusy.value = true
  try { await revokeBalanceQueryKey(); keyEnabled.value = false; freshQueryKey.value = '' } catch (error) { console.error('Failed to revoke balance query key:', error) } finally { keyBusy.value = false }
}

async function copyQueryKey() { await navigator.clipboard.writeText(freshQueryKey.value) }

onMounted(async () => {
  void refreshQueryKeyStatus()
  const profileRefresh = authStore.refreshUser().catch((error) => {
    console.error('Failed to refresh profile:', error)
  })

  const settingsLoad = appStore.fetchPublicSettings()
    .then((settings) => {
      if (!settings) {
        return
      }
      contactInfo.value = settings.contact_info || ''
      balanceLowNotifyEnabled.value = settings.balance_low_notify_enabled ?? false
      systemDefaultThreshold.value = settings.balance_low_notify_threshold ?? 0
      linuxdoOAuthEnabled.value = settings.linuxdo_oauth_enabled ?? false
      dingtalkOAuthEnabled.value = settings.dingtalk_oauth_enabled ?? false
      wechatOAuthEnabled.value = isWeChatWebOAuthEnabled(settings)
      wechatOAuthOpenEnabled.value = typeof settings.wechat_oauth_open_enabled === 'boolean'
        ? settings.wechat_oauth_open_enabled
        : undefined
      wechatOAuthMPEnabled.value = typeof settings.wechat_oauth_mp_enabled === 'boolean'
        ? settings.wechat_oauth_mp_enabled
        : undefined
      oidcOAuthEnabled.value = settings.oidc_oauth_enabled ?? false
      oidcOAuthProviderName.value = settings.oidc_oauth_provider_name || 'OIDC'
      passkeyEnabled.value = settings.passkey_enabled === true
    })
    .catch((error) => {
      console.error('Failed to load settings:', error)
    })

  await Promise.all([profileRefresh, settingsLoad])
})
</script>
