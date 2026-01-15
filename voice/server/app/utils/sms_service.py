"""短信验证码服务"""
import random
import time
from typing import Dict, Optional
from datetime import datetime, timedelta


class SMSService:
    """短信验证码服务（简化版，实际应使用阿里云、腾讯云等）"""

    def __init__(self):
        # 使用内存存储验证码（生产环境应使用Redis）
        self._codes: Dict[str, Dict] = {}
        self._send_records: Dict[str, list] = {}  # 发送记录，用于限流

    def send_code(self, phone: str) -> bool:
        """
        发送验证码

        Args:
            phone: 手机号

        Returns:
            是否发送成功

        Raises:
            ValueError: 如果发送过于频繁
        """
        # 检查发送频率限制（60秒内只能发送一次）
        if not self._check_send_limit(phone):
            raise ValueError("发送过于频繁，请稍后再试")

        # 生成6位随机验证码
        code = str(random.randint(100000, 999999))

        # 存储验证码（5分钟有效期）
        self._codes[phone] = {
            'code': code,
            'expire_time': datetime.now() + timedelta(minutes=5),
            'attempts': 0  # 验证尝试次数
        }

        # 记录发送时间
        if phone not in self._send_records:
            self._send_records[phone] = []
        self._send_records[phone].append(datetime.now())

        # 实际生产环境这里应该调用短信服务商API发送短信
        # 例如：阿里云短信、腾讯云短信等
        print(f"[SMS] 发送验证码到 {phone}: {code}")

        # TODO: 集成真实的短信服务
        # 示例：
        # from aliyunsdkcore.client import AcsClient
        # from aliyunsdkcore.request import CommonRequest
        # client = AcsClient('<accessKeyId>', '<accessSecret>', 'cn-hangzhou')
        # request = CommonRequest()
        # request.set_domain('dysmsapi.aliyuncs.com')
        # request.set_method('POST')
        # request.set_version('2017-05-25')
        # request.set_action_name('SendSms')
        # request.add_query_param('PhoneNumbers', phone)
        # request.add_query_param('SignName', '你的签名')
        # request.add_query_param('TemplateCode', '模板CODE')
        # request.add_query_param('TemplateParam', f'{{"code":"{code}"}}')
        # response = client.do_action_with_exception(request)

        return True

    def verify_code(self, phone: str, code: str) -> bool:
        """
        验证验证码

        Args:
            phone: 手机号
            code: 验证码

        Returns:
            是否验证成功
        """
        if phone not in self._codes:
            return False

        code_info = self._codes[phone]

        # 检查是否过期
        if datetime.now() > code_info['expire_time']:
            del self._codes[phone]
            return False

        # 检查验证次数（最多3次）
        if code_info['attempts'] >= 3:
            del self._codes[phone]
            raise ValueError("验证码错误次数过多，请重新获取")

        # 验证码校验
        if code_info['code'] == code:
            # 验证成功，删除验证码
            del self._codes[phone]
            return True
        else:
            # 验证失败，增加尝试次数
            code_info['attempts'] += 1
            return False

    def _check_send_limit(self, phone: str) -> bool:
        """
        检查发送频率限制

        Args:
            phone: 手机号

        Returns:
            是否可以发送
        """
        if phone not in self._send_records:
            return True

        # 清理过期的发送记录（超过1小时）
        now = datetime.now()
        self._send_records[phone] = [
            t for t in self._send_records[phone]
            if now - t < timedelta(hours=1)
        ]

        # 检查60秒内是否发送过
        recent_sends = [
            t for t in self._send_records[phone]
            if now - t < timedelta(seconds=60)
        ]

        if recent_sends:
            return False

        # 检查1小时内发送次数（最多10次）
        if len(self._send_records[phone]) >= 10:
            return False

        return True

    def get_remaining_time(self, phone: str) -> Optional[int]:
        """
        获取距离下次可发送的剩余秒数

        Args:
            phone: 手机号

        Returns:
            剩余秒数，如果可以立即发送则返回None
        """
        if phone not in self._send_records or not self._send_records[phone]:
            return None

        last_send = self._send_records[phone][-1]
        elapsed = (datetime.now() - last_send).total_seconds()

        if elapsed >= 60:
            return None

        return int(60 - elapsed)


# 全局单例
_sms_service = SMSService()


def get_sms_service() -> SMSService:
    """获取短信服务实例"""
    return _sms_service
