Актуальное:

- Переработал dbram 
- В fifo.vhd работаю над тем, чтобы прикрутить к памяти fifo (ещё не завершил)

**Запуск симуляции**
```
cd .\repo\sim\questa
.\run.bat gui
```

Чтобы запустить fifo, замените в run.bat simulate_gui.do на simulate_fifo.do и в compile.do раскоментить нужный tb (потом сделаю по-человечески) 