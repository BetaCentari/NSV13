import { BooleanLike } from '../../common/react';
import { useBackend } from '../backend';
import { Stack, Box, Button, Table, Section, ProgressBar } from '../components';
import { Window } from '../layouts';

type chaingunData = {
  loaded: number;
  chambered: number;
  safety: BooleanLike;
  ammo: number;
  max_ammo: number;
  cycler_firerate: number;
  gyroscope_alignment: number;
  max_gyroscope_alignment: number;
  hopper_belts: number;
  max_hopper_belts: number;
};

export const chaingun = (props, context) => {
  const { act, data } = useBackend<chaingunData>(context);
  const {
    loaded,
    chambered,
    safety,
    ammo,
    max_ammo,
    cycler_firerate,
    gyroscope_alignment,
    max_gyroscope_alignment,
    hopper_belts,
    max_hopper_belts,
  } = data;

  return (
    <Window resizable width={560} height={600}>
      <Window.Content scrollable>
        <Section>
          <Section>
            <Stack wrap="wrap" spacing={1} direction="row">
              <Stack.Item width="200px">
                <Section title="Controls">
                  <Button
                    fluid
                    icon={loaded ? 'check-circle' : 'square-o'}
                    width="100"
                    selected={loaded}
                    textAlign="center"
                    color={loaded ? 'green' : 'red'}
                    content="Feed Belt"
                    onClick={() => act('toggle_load')}
                  />
                  <Button
                    fluid
                    icon={chambered ? 'check-circle' : 'square-o'}
                    width="100"
                    textAlign="center"
                    selected={chambered}
                    color={chambered ? 'green' : 'red'}
                    content="Chamber Round"
                    onClick={() => act('chamber')}
                  />
                  <Button
                    icon={safety ? 'power-off' : 'times'}
                    fluid
                    textAlign="center"
                    color={safety ? 'green' : 'red'}
                    content="Weapon Safeties"
                    onClick={() => act('toggle_safety')}
                  />
                  <Button fluid textAlign="center" color="good" content="Manual Cycle" onClick={() => act('manual_cycle')} />
                </Section>
              </Stack.Item>
              <Stack.Item grow>
                <Section title="Info" position="relative" height="100%">
                  <Box height="100px" textAlign="center">
                    <Box>Cycler Firerate: {cycler_firerate * 60}RPM</Box>
                    <Box>
                      Gyroscope Alignment
                      <ProgressBar
                        value={(gyroscope_alignment / max_gyroscope_alignment) * 100 * 0.01}
                        ranges={{
                          good: [0.5, Infinity],
                          average: [0.15, 0.5],
                          bad: [-Infinity, 0.15],
                        }}
                      />
                    </Box>
                    <Box>
                      Ammo: {ammo}/{max_ammo}
                      <ProgressBar
                        value={(ammo / max_ammo) * 100 * 0.01}
                        ranges={{
                          good: [0.5, Infinity],
                          average: [0.15, 0.5],
                          bad: [-Infinity, 0.15],
                        }}
                      />
                      <br />
                      Belts: {hopper_belts}/{max_hopper_belts}
                      <ProgressBar
                        value={(hopper_belts / max_hopper_belts) * 100 * 0.01}
                        ranges={{
                          good: [0.5, Infinity],
                          average: [0.15, 0.5],
                          bad: [-Infinity, 0.15],
                        }}
                      />
                    </Box>
                  </Box>
                </Section>
              </Stack.Item>
            </Stack>
          </Section>
        </Section>
      </Window.Content>
    </Window>
  );
};
