import math, random, string

def gen_code(n=8): 
    return ''.join(random.choices(string.ascii_uppercase+string.digits, k=n))

def haversine(lat1,lng1,lat2,lng2):
    R=6371000
    phi1,phi2=math.radians(lat1),math.radians(lat2)
    dphi=math.radians(lat2-lat1); dl=math.radians(lng2-lng1)
    a=math.sin(dphi/2)**2+math.cos(phi1)*math.cos(phi2)*math.sin(dl/2)**2
    return 2*R*math.asin(math.sqrt(a))
