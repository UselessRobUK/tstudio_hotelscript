const resourceName = (window as any).GetParentResourceName?.() ?? 'tstudio_hotelscript'

export async function nuiPost<T = unknown>(endpoint: string, payload: unknown = {}): Promise<T> {
    const resp = await fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    })
    return resp.json() as Promise<T>
}
