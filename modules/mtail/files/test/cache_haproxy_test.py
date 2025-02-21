import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class CacheHAProxyTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/cache_haproxy.mtail'),
                os.path.join(test_dir, 'logs/cache_haproxy.test'))

    def testClientMetrics(self):
        s = self.store.get_samples('haproxy_client_ttfb')
        s_dict = dict(s)

        count_2xx = s_dict['cache_status=hit,http_status_family=2']['count']
        self.assertEqual(count_2xx, 1)
        count_2xx = s_dict['cache_status=miss,http_status_family=2']['count']
        self.assertEqual(count_2xx, 1)
        count_2xx = s_dict['cache_status=int-front,http_status_family=2']['count']
        self.assertEqual(count_2xx, 1)
        count_4xx = s_dict['cache_status=int-front,http_status_family=4']['count']
        self.assertEqual(count_4xx, 2)

        self.assertEqual(s_dict['cache_status=int-front,http_status_family=4']['buckets']['0.045'],
                         2)
        self.assertEqual(s_dict['cache_status=hit,http_status_family=2']['buckets']['0.07'], 1)
        self.assertEqual(s_dict['cache_status=miss,http_status_family=2']['buckets']['0.15'], 1)

        s = self.store.get_samples('haproxy_client_healthcheck_ttfb')
        s_dict = dict(s)

        count_2xx = s_dict['cache_status=int-front,http_status_family=2']['count']
        self.assertEqual(count_2xx, 1)
